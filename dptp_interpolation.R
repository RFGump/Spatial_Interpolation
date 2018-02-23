setwd('/rhome/pld9230/weather')

#-------------------------------------------------------------------------------------------------
# read data
#-------------------------------------------------------------------------------------------------

library("RODBC",lib.loc="/rlib/library/RODBC_1.3-7")

channel <- odbcConnect(dsn='23W_SANDBOX_ADHOC',
                       uid=db23w_adhoc$uid, 
                       pwd=db23w_adhoc$pwd)

dptp <- sqlQuery(channel,
                 "select
                    geofips
                   ,lat
                   ,lon
                   ,ObsDt
                   ,year(ObsDt) as ObsYr
                   ,dptp
                  from PC_ACTUARY_SANDBOX_adhoc.dbo.mdn_weather",
                  as.is=c(TRUE,FALSE,FALSE,FALSE,FALSE,FALSE))

dptp <- dptp[!is.na(dptp$lat),]     # remove invalid geocodes (51515 was retired)
dptp$cnt<-seq(nrow(dptp))           # add an index variable
dptp$ObsDt <- as.Date(dptp$ObsDt)

sum(is.na(dptp$dptp))  # 3,142,072 missing values

dptp0 <- dptp[is.na(dptp$dptp),]
dptp1 <- dptp[!is.na(dptp$dptp),]

dptp0 <- dptp0[order(dptp0$ObsDt), ]   # sort by date
dptp1 <- dptp1[order(dptp1$ObsDt), ]   # sort by date

dptp0_ak <- dptp0[substr(dptp0$geofips,1,2)=='02',]
dptp0_hi <- dptp0[substr(dptp0$geofips,1,2)=='15',]
dptp0 <- dptp0[!(substr(dptp0$geofips,1,2) %in% c('02','15')),]  # drop alaska and hawaii.  handle separately.

dptp1_ak <- dptp1[substr(dptp1$geofips,1,2)=='02',]
dptp1_hi <- dptp1[substr(dptp1$geofips,1,2)=='15',]
dptp1 <- dptp1[!(substr(dptp1$geofips,1,2) %in% c('02','15')),]  # drop alaska and hawaii.  handle separately.


#-------------------------------------------------------------------------------------------------
# define smoothing process
#-------------------------------------------------------------------------------------------------

# smoothing function to be applied in spatial interpolation
smooth_fun_01 <- function(df) {
  c(nrow(df),weighted.mean(df$dptp, df$weights))
}

# haversine distance calculation
haver <- function(lat1, lon1, lat2, lon2, km = TRUE){
  if(km) R <- 6371 else R <- 3959    # earth's average radius in miles or kilometers
  a <- sin((lat1 - lat2)*pi/360)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin((lon1-lon2)*pi/360)^2
  # a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
  c <- 2 * atan2(sqrt(a),sqrt(1-a))
  #c = 2 ⋅ atan2( √a, √(1−a) )
  R * c
}

library(parallel)

# spatial interpolation function
SpInt<-function(df_0, df_1, max_distance, max_days, smooth_fun){
  res <- mcmapply(
    function(x, y, t){
      df_nb <- df_1[abs(difftime(df_1$ObsDt, t, units = 'days')) <= max_days & 
                      haver(df_1$lat, df_1$lon, y, x, km = FALSE) <= max_distance, ]
      df_nb$sp_dist <- haver(df_nb$lat, df_nb$lon, y, x, km = FALSE)
      df_nb$tm_dist <- as.numeric(abs(difftime(df_nb$ObsDt, t, units = 'days'))) * 50   # 1 day = 50 miles
      df_nb$weights <- 1 / sqrt(df_nb$sp_dist^2 + df_nb$tm_dist^2)
      #df_nb$weights <- 1 / (df_nb$sp_dist)^2
      return(smooth_fun(df_nb))
    },
    df_0$lon,    # x
    df_0$lat,    # y
    df_0$ObsDt,  # t
    mc.cores=3)
  return(t(res))
}


runSp<-function(df1,df2,step,radius,days){
  out<-matrix(nrow=0,ncol=3)
  for(i in 1:ceiling(nrow(df1)/step)){
    print((i-1)*step)
    df_a <- df1[((i-1)*step + 1):min((i*step),nrow(df1)),]
    df_b <- df2[df2$ObsDt <= max(df_a$ObsDt) + days &
                  df2$ObsDt >= min(df_a$ObsDt) - days,]
    out<-rbind(out,cbind(df_a$cnt,SpInt(df_a,df_b, radius, days, smooth_fun_01)))
  }
  return(out)
}

#-------------------------------------------------------------------------------------------------
# replace missing value with average of dptp for that location (+/- 100 miles) and 
# date (+/- 5 days)
#-------------------------------------------------------------------------------------------------


dptp0_a<-runSp(dptp0,dptp1,5000,100,5)
  summary(dptp0_a)  # 0 missing values
  dptp0_a <- data.frame(dptp0_a)
  names(dptp0_a) <- c('cnt','n0','dptp_1')

dptp0a <- merge(dptp0,dptp0_a,by="cnt")

#----------------------------------------------------------------------------------------------------------
# PROCESS ALASKA
#----------------------------------------------------------------------------------------------------------

dptp0_ak_1<-runSp(dptp0_ak,dptp1_ak,5000,50,5)
  summary(dptp0_ak_1)   # 25 missing values
  dptp0_ak_1 <- data.frame(dptp0_ak_1)
  names(dptp0_ak_1) <- c('cnt','n0','dptp_1')

  dptp0a_ak <- merge(dptp0_ak,dptp0_ak_1,by="cnt")

dptp0_ak_2<-runSp(dptp0a_ak[is.na(dptp0a_ak$dptp_1),],dptp1_ak,5000,150,5)
  summary(dptp0_ak_2)  # 0 missing values
  dptp0_ak_2 <- data.frame(dptp0_ak_2)
  names(dptp0_ak_2) <- c('cnt','n0','dptp_1')

dptp0_ak_a <- rbind(dptp0_ak_1[!is.na(dptp0_ak_1$dptp_1),], dptp0_ak_2)
  summary(dptp0_ak_a)

dptp0a_ak <- merge(dptp0_ak,dptp0_ak_a,by="cnt")
  summary(dptp0a_ak)

#----------------------------------------------------------------------------------------------------------
# PROCESS HAWAII
#----------------------------------------------------------------------------------------------------------

dptp0_hi_1<-runSp(dptp0_hi,dptp1_hi,5000,50,5)
  summary(dptp0_hi_1)   # 0 missing value
  dptp0_hi_1 <- data.frame(dptp0_hi_1)
  names(dptp0_hi_1) <- c('cnt','n0','dptp_1')

dptp0a_hi <- merge(dptp0_hi,dptp0_hi_1,by="cnt")

#----------------------------------------------------------------------------------------------------------
# EXPORT RESULTS TO SQL SERVER
#----------------------------------------------------------------------------------------------------------

mdn_dptp0 <- rbind(dptp0a,
                   dptp0a_ak,
                   dptp0a_hi)

channel <- odbcConnect(dsn='23W_SANDBOX_ADHOC', uid=db23w_adhoc$uid, pwd=db23w_adhoc$pwd)
mdn_dptp0$ObsDt <- as.character(mdn_dptp0$ObsDt)
sqlSave(channel, dat=mdn_dptp0, rownames = FALSE)




