# Spatial_Interpolation

Code for imputing missing values in weather data

## Step 1: Update GLM Weather Variables
The Colossus program extracts the data in a .dbf format.  Based on this data format, the output files cannot be larger than 2.0 GB.  In addition, the path and filename must not include any spaces.

Right click on Colossus.exe and select “Run as administrator.”  When requested, enter your user ID and password.
•	Step 1 – Database Selection
-	Select the database for the years desired
•	Step 2 – Geographic Coverage
-	Select the states desired.  In this case, all states were selected.
•	Step 3 – Desired Datasets
-	Select the weather variable desired.  Due to the limitations of the .dbf format, only one variable at a time should be selected.
•	Step 4 – Output Options
-	Time Frame – select years desired (limit number of years to 5 due to .dbf limitations).
-	Output time period – select ‘Daily’
-	Database Format – select ‘Single Column Format’
-	Not Available (NA) Handling Options – Select ‘Handle as Text’

Preliminary Data Evaluation

Missing values by year

|Year | cldg | htdg | dptp | mnrh | prcp | pres | snow | snwd | tmax | tmin | tmpw | wndd | wnds |
|:----|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:|-----:| 
| 2000 | 0.06% | 0.06% | 29.45% | 29.49% | 2.12% | 37.86% | 38.44% | 37.58% | 0.05% | 0.05% | 0.06% | 43.82% | 28.83%|
| 2001 | 0.08% | 0.08% | 27.18% | 27.21% | 0.96% | 36.00% | 37.29% | 37.51% | 0.06% | 0.07% | 0.08% | 43.92% | 32.47%|
| 2002 | 0.07% | 0.07% | 25.29% | 25.32% | 0.83% | 34.66% | 36.75% | 37.32% | 0.05% | 0.06% | 0.07% | 39.21% | 25.63%|
| 2003 | 0.11% | 0.11% | 24.17% | 24.27% | 0.78% | 34.72% | 35.81% | 36.10% | 0.10% | 0.10% | 0.11% | 37.86% | 23.39%|
| 2004 | 0.11% | 0.11% | 21.20% | 21.26% | 0.67% | 34.57% | 34.06% | 35.11% | 0.10% | 0.11% | 0.11% | 34.69% | 20.48%|
| 2005 | 0.10% | 0.10% | 18.03% | 18.04% | 0.57% | 34.08% | 30.84% | 32.36% | 0.09% | 0.10% | 0.10% | 32.29% | 17.15%|
| 2006 | 0.06% | 0.06% | 17.15% | 17.16% | 0.40% | 33.33% | 26.18% | 30.73% | 0.04% | 0.06% | 0.06% | 30.46% | 16.03%|
| 2007 | 0.07% | 0.07% | 16.07% | 16.07% | 0.31% | 32.67% | 18.63% | 27.65% | 0.05% | 0.06% | 0.07% | 30.55% | 14.97%|
| 2008 | 0.07% | 0.07% | 15.37% | 15.38% | 0.17% | 33.17% | 6.43% | 22.11% | 0.05% | 0.06% | 0.07% | 29.88% | 14.12%|
| 2009 | 0.08% | 0.08% | 14.89% | 14.90% | 0.10% | 32.03% | 4.74% | 16.13% | 0.06% | 0.07% | 0.08% | 28.44% | 13.42%|
| 2010 | 0.08% | 0.08% | 14.26% | 14.26% | 0.10% | 32.03% | 3.22% | 14.10% | 0.06% | 0.08% | 0.08% | 28.79% | 12.87%|
| 2011 | 0.04% | 0.04% | 12.62% | 12.63% | 0.08% | 31.92% | 2.42% | 11.81% | 0.03% | 0.04% | 0.04% | 25.87% | 11.43%|
| 2012 | 0.01% | 0.01% | 11.35% | 11.35% | 0.07% | 31.80% | 1.81% | 10.24% | 0.01% | 0.01% | 0.01% | 25.55% | 10.10%|
| 2013 | 0.07% | 0.07% | 10.88% | 10.89% | 0.06% | 31.85% | 1.55% | 6.90% | 0.07% | 0.07% | 0.07% | 23.69% | 9.67%|
| 2014 | 0.08% | 0.08% | 10.43% | 10.44% | 0.06% | 31.83% | 1.40% | 5.62% | 0.08% | 0.08% | 0.08% | 22.20% | 9.34%|
| 2015 | 0.14% | 0.14% | 10.07% | 10.07% | 0.08% | 31.76% | 1.88% | 5.90% | 0.14% | 0.14% | 0.14% | 20.52% | 9.11%|

Conclusions:
•	tmin, tmax, and prcp have consistently low levels of missing values
•	cldg, htdg, and tmpw can be derived from tmin and tmax when missing
•	level of missing values has improved for some variables in more recent years
•	wndd has high levels of missing values and isn’t very useful in models – decision to omit
•	snow should be zero when prcp is zero

## Step 2: Combine data in SAS
•	Transfer .dbf file to the SAS server via WinSCP.
•	The following program was used to read the .dbf files and combine them into a single SAS dataset.

options mlogic mprint merror;
%macro wthrin(invar);

proc import out=&invar._1970 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1970_1974.dbf" dbms=dbf replace; run;
proc import out=&invar._1975 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1975_1979.dbf" dbms=dbf replace; run;
proc import out=&invar._1980 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1980_1984.dbf" dbms=dbf replace; run;
proc import out=&invar._1985 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1985_1989.dbf" dbms=dbf replace; run;
proc import out=&invar._1990 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1990_1994.dbf" dbms=dbf replace; run;
proc import out=&invar._1995 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._1995_1999.dbf" dbms=dbf replace; run;
proc import out=&invar._2000 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._2000_2004.dbf" dbms=dbf replace; run;
proc import out=&invar._2005 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._2005_2009.dbf" dbms=dbf replace; run;
proc import out=&invar._2010 datafile = "/sas3l_raw35/pncactm/MDN/weather/&invar._2010_2015-07.dbf" dbms=dbf replace; run;

data &invar (drop=varname itemvalue);
  set &invar._1970 &invar._1975 &invar._1980 &invar._1985 &invar._1990 &invar._1995 &invar._2000 &invar._2005 &invar._2010;
  &invar = itemvalue + 0;
run;

proc sql;
  drop table &invar._1970,&invar._1975,&invar._1980,&invar._1985,&invar._1990,&invar._1995,&invar._2000,&invar._2005,&invar._2010;
quit;

%mend;

%wthrin(cldg);
%wthrin(dptp);
%wthrin(htdg);
%wthrin(mnrh);
%wthrin(prcp);
%wthrin(pres);
%wthrin(snow);
%wthrin(snwd);
%wthrin(tmax);
%wthrin(tmin);
%wthrin(tmpw);
%wthrin(wndd);
%wthrin(wnds);

proc sort data=cldg; by geofips timeframe; run;
proc sort data=dptp; by geofips timeframe; run;
proc sort data=htdg; by geofips timeframe; run;
proc sort data=mnrh; by geofips timeframe; run;
proc sort data=prcp; by geofips timeframe; run;
proc sort data=pres; by geofips timeframe; run;
proc sort data=snow; by geofips timeframe; run;
proc sort data=snwd; by geofips timeframe; run;
proc sort data=tmax; by geofips timeframe; run;
proc sort data=tmin; by geofips timeframe; run;
proc sort data=tmpw; by geofips timeframe; run;
proc sort data=wndd; by geofips timeframe; run;
proc sort data=wnds; by geofips timeframe; run;

data pncactm.weather;
  merge cldg dptp htdg mnrh prcp pres snow snwd tmax tmin tmpw wndd wnds;
  by geofips timeframe;
run;

proc sql;
  drop table cldg,dptp,htdg,mnrh,prcp,pres,snow,snwd,tmax,tmin,tmpw,wndd,wnds;
quit;

## Step 3: Attach latitude, longitude, and county names
•	Download the county shapefile from the US Census website.
https://catalog.data.gov/dataset/tiger-line-shapefile-2014-nation-u-s-current-county-and-equivalent-national-shapefile
•	Transfer the .dbf file to SAS
•	Create additional variables (year, day, state_fips, cnty_fips)
•	Merge the shapefile with the weather data to get latitude and longitude.
proc sort data=pncactm.weather; by geofips; run;
proc sort data=me.counties; by fips; run;

data pncactm.weather;
  merge pncactm.weather (in=in1)
        me.counties (rename=(fips=geofips));
  by geofips;

  if in1;

  year = input(substr(timeframe,2,4),4.);
  day = input(substr(timeframe,7,3),3.);

  state_fips = substr(geofips,1,2);
  cnty_fips = substr(geofips,3,3);

run;

proc sort data=me.tl_2014_us_county; by geoid; run;
data pncactm.weather;
  merge pncactm.weather (in=in1)
        me.tl_2014_us_county (rename=(geoid=geofips intptlat=lat intptlon=lon)
                     drop=name namelsad);
  by geofips;

  if in1;
run;

data pncactm.weather;
  set pncactm.weather;
  ObsDt = datejul(year*1000 + day);
  format ObsDt date9.;
run;

## Step 4: Impute missing values in R
•	Transfer weather file back to SQL server for use in R.  
-	I limited this file to years 2000 and forward.
•	R Programs\tmin_interpolation.R
•	R Programs\tmax_interpolation.R
•	R Programs\prcp_interpolation.R
•	R Programs\wnds_interpolation.R
•	R Programs\dptp_interpolation.R
•	R Programs\mnrh_interpolation.R
•	R Programs\snow_interpolation.R
•	R Programs\snwd_interpolation.R
•	R Programs\pres_interpolation.R

## Step 5: Calculate derived variables in SAS
•	Average temperature, cooling degree days, and heating degree days can be calculated based on values of high and low temperatures.
data pncactm.weather_temp;
  set pncactm.weather_temp;

  if tmpw = . then tmpw_1 = (tmin_1+tmax_1)/2;
              else tmpw_1 = tmpw;
  if cldg = . then cldg_1 = max(tmpw - 75, 0);
              else cldg_1 = cldg;
  if htdg = . then htdg_1 = max(65 - tmpw, 0);
              else htdg_1 = htdg;
run;
•	Multiplied dummy variables by 100 to increase values of statistics
data pncactm.glm_weather_day_200001_201507;
  set pncactm.weather_temp (where=(lat ne .));

  trng = tmax_1 - tmin_1;
  *tmid = (tmax_1 + tmin_1)/2;

  /* calculate indicator variables */
  if tmax_1 >= 90 then tmax90 = 100; else tmax90 = 0;
  if tmin_1 <= 32 then tmin32 = 100; else tmin32 = 0;

  if prcp_1 > 0 then prcpany = 100; else prcpany = 0;
  if prcp_1 >= 1 then prcp1 = 100; else prcp1 = 0;
  if prcp_1 >= 2 then prcp2 = 100; else prcp2 = 0;

  if wnds_1 >= 10 then wnds10 =100; else wnds10 = 0;
  if wnds_1 >= 15 then wnds15 =100; else wnds15 = 0;
  if wnds_1 >= 20 then wnds20 =100; else wnds20 = 0;

  if snow_1 > 0 then snowany= 100; else snowany = 0;

  FrzPrcp = prcpany * tmin32 / 100;

run;

## Step 6: Compute statistics for each variable
•	Max, Min, and Range don’t need to be calculated for dummy variables
•	Missing values exist for kurtosis, skewness, and coefficient of variation when variable has only one value.
/* Calculate stats for daily observations */
proc means data=pncactm.glm_weather_day_200001_201507 noprint nway missing;
  class geofips;
  var cldg_1 dptp_1 htdg_1 mnrh_1 prcp_1 pres_1 snow_1 snwd_1 tmax_1 tmin_1 tmpw_1 wnds_1 trng;
  output out=glm_weather_1 (drop=_type_ _freq_)
    mean=  cldg_av dptp_av htdg_av mnrh_av prcp_av pres_av snow_av snwd_av tmax_av tmin_av tmpw_av wnds_av trng_av
    std=   cldg_sd dptp_sd htdg_sd mnrh_sd prcp_sd pres_sd snow_sd snwd_sd tmax_sd tmin_sd tmpw_sd wnds_sd trng_sd
    skew=  cldg_sk dptp_sk htdg_sk mnrh_sk prcp_sk pres_sk snow_sk snwd_sk tmax_sk tmin_sk tmpw_sk wnds_sk trng_sk
    kurt=  cldg_kt dptp_kt htdg_kt mnrh_kt prcp_kt pres_kt snow_kt snwd_kt tmax_kt tmin_kt tmpw_kt wnds_kt trng_kt
    range= cldg_rg dptp_rg htdg_rg mnrh_rg prcp_rg pres_rg snow_rg snwd_rg tmax_rg tmin_rg tmpw_rg wnds_rg trng_rg
    cv=    cldg_cv dptp_cv htdg_cv mnrh_cv prcp_cv pres_cv snow_cv snwd_cv tmax_cv tmin_cv tmpw_cv wnds_cv trng_cv
    max=   cldg_mx dptp_mx htdg_mx mnrh_mx prcp_mx pres_mx snow_mx snwd_mx tmax_mx tmin_mx tmpw_mx wnds_mx trng_mx
    min=   cldg_mn dptp_mn htdg_mn mnrh_mn prcp_mn pres_mn snow_mn snwd_mn tmax_mn tmin_mn tmpw_mn wnds_mn trng_mn;
run;

proc means data=pncactm.glm_weather_day_200001_201507 noprint nway missing;
  class geofips;
  var FrzPrcp prcp1 prcp2 prcpany snowany tmax90 tmin32 wnds10 wnds15 wnds20;
  output out=glm_weather_2 (drop=_type_ _freq_)
    mean=  FrzPrcp_av prcp1_av prcp2_av prcpany_av snowany_av tmax90_av tmin32_av wnds10_av wnds15_av wnds20_av
    std=   FrzPrcp_sd prcp1_sd prcp2_sd prcpany_sd snowany_sd tmax90_sd tmin32_sd wnds10_sd wnds15_sd wnds20_sd
    skew=  FrzPrcp_sk prcp1_sk prcp2_sk prcpany_sk snowany_sk tmax90_sk tmin32_sk wnds10_sk wnds15_sk wnds20_sk
    kurt=  FrzPrcp_kt prcp1_kt prcp2_kt prcpany_kt snowany_kt tmax90_kt tmin32_kt wnds10_kt wnds15_kt wnds20_kt
    cv=    FrzPrcp_cv prcp1_cv prcp2_cv prcpany_cv snowany_cv tmax90_cv tmin32_cv wnds10_cv wnds15_cv wnds20_cv;
run;

proc sort data=glm_weather_1; by geofips; run;
proc sort data=glm_weather_2; by geofips; run;

data pncactm.glm_weather_sum_200001_201507;
  merge glm_weather_1 glm_weather_2;
  by geofips;
run;


