setwd('/rhome/pld9230/weather')

#-------------------------------------------------------------------------------------------------
# read data
#-------------------------------------------------------------------------------------------------

library("RODBC",lib.loc="/rlib/library/RODBC_1.3-7")

channel <- odbcConnect(dsn='23W_SANDBOX_ADHOC',
                       uid=db23w_adhoc$uid, 
                       pwd=db23w_adhoc$pwd)

wthr <- sqlQuery(channel,
                 "select
                    geofips as GEOID
                   ,lat
                   ,lon
                   ,ObsDt
                   ,year(ObsDt) as ObsYr
                   ,dptp
                   ,mnrh
                   ,prcp
                   ,pres
                   ,snow
                   ,snwd
                   ,tmax
                   ,tmin
                   ,wnds
                  from PC_ACTUARY_SANDBOX_adhoc.dbo.mdn_weather",
                 as.is=c(TRUE,rep(FALSE,13)))

wthr <- wthr[!is.na(wthr$lat),]     # remove invalid geocodes (51515 was retired) 5691 records dropped
wthr$cnt<-seq(nrow(wthr))           # add an index variable
wthr$ObsDt <- as.Date(wthr$ObsDt)

miss <- aggregate(is.na(wthr[,6:14]),by=list(wthr$GEOID),FUN=sum)
no.miss <- aggregate(!is.na(wthr[,6:14]),by=list(wthr$GEOID),FUN=sum)

pct.miss <- cbind(GEOID=miss[,1], round(miss[,-1]/(miss[,-1] + no.miss[,-1]),4))

head(pct.miss,30)

#----------------------------------------------------------------------------------------------
# Draw Map
#----------------------------------------------------------------------------------------------

library(sp)
library(RColorBrewer)
library(classInt)
library(gstat)
library(maptools)

cnty<-readShapeSpatial('county')
  names(cnty)
  class(cnty)

cnty_1 <- merge(cnty, pct.miss, by = "GEOID")

#breaks <- classIntervals(cnty_1[['snow']],n=6,style='quantile')$brks
#plotclr <- brewer.pal(6,"Spectral")

states <- c('01','02','04','05','06','08','09','10','11','12','13','15','16','17','18','19','20','21','22','23','24',
            '25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42','44','45','46',
            '47','48','49','50','51','53','54','55','56')

breaks1 <- seq(0,1.05,.05)

par(mar=c(1,1,1,1))  # bottom, left, top, right
spplot(cnty_1[cnty_1$STATEFP %in% states,],'tmax',scales = list(draw = F),
       #main='PRES (% missing)',
       ylim = c(23,50),
       xlim=c(-126,-66.5),
       par.settings = list(axis.line = list(col = 'transparent')),
       col='transparent',
       #col.regions=plotclr,
       at=breaks1)

par(mar=c(1,1,1,1))  # bottom, left, top, right
spplot(cnty_1[cnty_1$STATEFP == '02',],'wnds',scales = list(draw = F),
       #main='PRES (% missing)',
       ylim = c(50,72),
       xlim=c(-180,-128),
       colorkey = F,
       par.settings = list(axis.line = list(col = 'transparent')),
       col='transparent',
       #col.regions=plotclr,
       at=breaks1)

par(mar=c(1,1,1,1))  # bottom, left, top, right
spplot(cnty_1[cnty_1$STATEFP == '15',],'wnds',scales = list(draw = F),
       #main='PRES (% missing)',
       ylim = c(18.5,22.5),
       xlim=c(-161,-154),
       colorkey = F,
       par.settings = list(axis.line = list(col = 'transparent')),
       col='transparent',
       #col.regions=plotclr,
       at=breaks1)

#-------------------------------------------------------------------------------------------------
# Summary of missing by year
#-------------------------------------------------------------------------------------------------

aggregate(is.na(wthr[,6:14]),by=list(wthr$ObsYr),FUN=sum)
aggregate(!is.na(wthr[,6:14]),by=list(wthr$ObsYr),FUN=sum)
