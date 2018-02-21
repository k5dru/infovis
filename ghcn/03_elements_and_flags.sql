/* from https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt */ 

drop table elements; 

create table elements ( 
  element varchar(4) primary key, 
  description varchar(255) not null
);

insert into elements values ('PRCP','Precipitation (tenths of mm)')
, ('SNOW','Snowfall (mm)')
, ('SNWD','Snow depth (mm)')
, ('TMAX','Maximum temperature (tenths of degrees C)')
, ('TMIN','Minimum temperature (tenths of degrees C)')
, ('ACMC','Average cloudiness midnight to midnight from 30-second ceilometer data (percent)')
, ('ACMH','Average cloudiness midnight to midnight from manual observations (percent)')
, ('ACSC','Average cloudiness sunrise to sunset from 30-second ceilometer data (percent)')
, ('ACSH','Average cloudiness sunrise to sunset from manual observations (percent)')
, ('AWDR','Average daily wind direction (degrees)')
, ('AWND','Average daily wind speed (tenths of meters per second)')
, ('DAEV','Number of days included in the multiday evaporation total (MDEV)')
, ('DAPR','Number of days included in the multiday precipiation total (MDPR)')
, ('DASF','Number of days included in the multiday snowfall total (MDSF)')  
, ('DATN','Number of days included in the multiday minimum temperature (MDTN)')
, ('DATX','Number of days included in the multiday maximum temperature (MDTX)')
, ('DAWM','Number of days included in the multiday wind movement (MDWM)')
, ('DWPR','Number of days with non-zero precipitation included in multiday precipitation total (MDPR)')
, ('EVAP','Evaporation of water from evaporation pan (tenths of mm)')
, ('FMTM','Time of fastest mile or fastest 1-minute wind (hours and minutes, i.e., HHMM)')
, ('FRGB','Base of frozen ground layer (cm)')
, ('FRGT','Top of frozen ground layer (cm)')
, ('FRTH','Thickness of frozen ground layer (cm)')
, ('GAHT','Difference between river and gauge height (cm)')
, ('MDEV','Multiday evaporation total (tenths of mm; use with DAEV)')
, ('MDPR','Multiday precipitation total (tenths of mm; use with DAPR and DWPR, if available)')
, ('MDSF','Multiday snowfall total')
, ('MDTN','Multiday minimum temperature (tenths of degrees C; use with DATN)')
, ('MDTX','Multiday maximum temperature (tenths of degress C; use with DATX)')
, ('MDWM','Multiday wind movement (km)')
, ('MNPN','Daily minimum temperature of water in an evaporation pan (tenths of degrees C)')
, ('MXPN','Daily maximum temperature of water in an evaporation pan (tenths of degrees C)')
, ('PGTM','Peak gust time (hours and minutes, i.e., HHMM)')
, ('PSUN','Daily percent of possible sunshine (percent)')
, ('TAVG','Average temperature (tenths of degrees C) [Note that TAVG from source _S_ corresponds to an average for the period ending at 2400 UTC rather than local midnight]')
, ('THIC','Thickness of ice on water (tenths of mm)')
, ('TOBS','Temperature at the time of observation (tenths of degrees C)')
, ('TSUN','Daily total sunshine (minutes)')
, ('WDF1','Direction of fastest 1-minute wind (degrees)')
, ('WDF2','Direction of fastest 2-minute wind (degrees)')
, ('WDF5','Direction of fastest 5-second wind (degrees)')
, ('WDFG','Direction of peak wind gust (degrees)')
, ('WDFI','Direction of highest instantaneous wind (degrees)')
, ('WDFM','Fastest mile wind direction (degrees)')
, ('WDMV','24-hour wind movement (km)')
, ('WESD','Water equivalent of snow on the ground (tenths of mm)')
, ('WESF','Water equivalent of snowfall (tenths of mm)')
, ('WSF1','Fastest 1-minute wind speed (tenths of meters per second)')
, ('WSF2','Fastest 2-minute wind speed (tenths of meters per second)')
, ('WSF5','Fastest 5-second wind speed (tenths of meters per second)')
, ('WSFG','Peak gust wind speed (tenths of meters per second)')
, ('WSFI','Highest instantaneous wind speed (tenths of meters per second)')
, ('WSFM','Fastest mile wind speed (tenths of meters per second)')
/*
     WT** = Weather Type where ** has one of the following values:
*/
, ('WT01','Weather Type: Fog, ice fog, or freezing fog (may include heavy fog)')
, ('WT02','Weather Type: Heavy fog or heaving freezing fog (not always distinquished from fog)')
, ('WT03','Weather Type: Thunder')
, ('WT04','Weather Type: Ice pellets, sleet, snow pellets, or small hail')
, ('WT05','Weather Type: Hail (may include small hail)')
, ('WT06','Weather Type: Glaze or rime')
, ('WT07','Weather Type: Dust, volcanic ash, blowing dust, blowing sand, or blowing obstruction')
, ('WT08','Weather Type: Smoke or haze')
, ('WT09','Weather Type: Blowing or drifting snow')
, ('WT10','Weather Type: Tornado, waterspout, or funnel cloud')
, ('WT11','Weather Type: High or damaging winds')
, ('WT12','Weather Type: Blowing spray')
, ('WT13','Weather Type: Mist')
, ('WT14','Weather Type: Drizzle')
, ('WT15','Weather Type: Freezing drizzle')
, ('WT16','Weather Type: Rain (may include freezing rain, drizzle, and freezing drizzle)')
, ('WT17','Weather Type: Freezing rain ')
, ('WT18','Weather Type: Snow, snow pellets, snow grains, or ice crystals')
, ('WT19','Weather Type: Unknown source of precipitation ')
, ('WT21','Weather Type: Ground fog ')
, ('WT22','Weather Type: Ice fog or freezing fog')
/* 
      WV** = Weather in the Vicinity where ** has one of the following values:
*/
, ('WV01','Weather in the Vicinity: Fog, ice fog, or freezing fog (may include heavy fog)')
, ('WV03','Weather in the Vicinity: Thunder')
, ('WV07','Weather in the Vicinity: Ash, dust, sand, or other blowing obstruction')
, ('WV18','Weather in the Vicinity: Snow or ice crystals')
, ('WV20','Weather in the Vicinity: Rain or snow shower')
;
/* 

     SN*# = Minimum soil temperature (tenths of degrees C)
            where * corresponds to a code
            for ground cover and # corresponds to a code for soil 
      depth.  
      
      Ground cover codes include the following:
      0 = unknown
      1 = grass
      2 = fallow
      3 = bare ground
      4 = brome grass
      5 = sod
      6 = straw multch
      7 = grass muck
      8 = bare muck
      
      Depth codes include the following:
      1 = 5 cm
      2 = 10 cm
      3 = 20 cm
      4 = 50 cm
      5 = 100 cm
      6 = 150 cm
      7 = 180 cm
*/ 
insert into elements
with cover as (
  select 0 as id, 'unknown' as desc 
union all select       1 , 'grass'
union all select       2 ,'fallow'
union all select       3 ,'bare ground'
union all select       4 ,'brome grass'
union all select       5 ,'sod'
union all select       6 ,'straw multch'
union all select       7 ,'grass muck'
union all select       8 ,'bare muck'
), 
depth as (
select      1 as id, '5 cm' as desc
union all select      2, '10 cm'
union all select      3, '20 cm'
union all select      4, '50 cm'
union all select      5, '100 cm'
union all select      6, '150 cm'
union all select      7, '180 cm'
)
select 'SN' || cover.id || depth.id, 'Minimum soil temperature (tenths of degrees C) for cover ' || cover.desc || ' soil depth ' || depth.desc
from cover 
cross join depth;

/* 
     SX*# = Maximum soil temperature (tenths of degrees C) 
            where * corresponds to a code for ground cover 
      and # corresponds to a code for soil depth. 
      See SN*# for ground cover and depth codes. 
*/
insert into elements
with cover as (
  select 0 as id, 'unknown' as desc 
union all select       1 , 'grass'
union all select       2 ,'fallow'
union all select       3 ,'bare ground'
union all select       4 ,'brome grass'
union all select       5 ,'sod'
union all select       6 ,'straw multch'
union all select       7 ,'grass muck'
union all select       8 ,'bare muck'
), 
depth as (
select      1 as id, '5 cm' as desc
union all select      2, '10 cm'
union all select      3, '20 cm'
union all select      4, '50 cm'
union all select      5, '100 cm'
union all select      6, '150 cm'
union all select      7, '180 cm'
)
select 'SX' || cover.id || depth.id, 'Maximum soil temperature (tenths of degrees C) for cover ' || cover.desc || ' soil depth ' || depth.desc
from cover 
cross join depth;

/* flags tables */ 

drop table mflags;
create table mflags (
    mflag char(1) primary key,
    description varchar(255)
); 

comment on column mflags.description is 'Measurement flag description';

insert into mflags values 
  ('B','precipitation total formed from two 12-hour totals')
, ('D','precipitation total formed from four six-hour totals')
, ('H','represents highest or lowest hourly temperature (TMAX or TMIN) or the average of hourly values (TAVG)')
, ('K','converted from knots')
, ('L','temperature appears to be lagged with respect to reported hour of observation')
, ('O','converted from oktas')
, ('P','identified as "missing presumed zero" in DSI 3200 and 3206')
, ('T','trace of precipitation, snowfall, or snow depth')
, ('W','converted from 16-point WBAN code (for wind direction)')
;

drop table qflags;
create table qflags (
    qflag char(1) primary key,
    description varchar(255)
); 
comment on column qflags.description is 'Quality flag description';

insert into qflags values 
  ('D','failed duplicate check')
, ('G','failed gap check')
, ('I','failed internal consistency check')
, ('K','failed streak/frequent-value check')
, ('L','failed check on length of multiday period ')
, ('M','failed megaconsistency check')
, ('N','failed naught check')
, ('O','failed climatological outlier check')
, ('R','failed lagged range check')
, ('S','failed spatial consistency check')
, ('T','failed temporal consistency check')
, ('W','temperature too warm for snow')
, ('X','failed bounds check')
, ('Z','flagged as a result of an official Datzilla investigation')
; 

drop table sflags;
create table sflags (
    sflag char(1) primary key,
    description varchar(512)
); 

comment on column sflags.description is 'Source flag description';

insert into sflags values 
  ('0', 'U.S. Cooperative Summary of the Day (NCDC DSI-3200)')
, ('6', 'CDMP Cooperative Summary of the Day (NCDC DSI-3206)')
, ('7', 'U.S. Cooperative Summary of the Day -- Transmitted via WxCoder3 (NCDC DSI-3207)')
, ('A', 'U.S. Automated Surface Observing System (ASOS) real-time data (since January 1, 2006)')
, ('a', 'Australian data from the Australian Bureau of Meteorology')
, ('B', 'U.S. ASOS data for October 2000-December 2005 (NCDC DSI-3211)')
, ('b', 'Belarus update')
, ('C', 'Environment Canada')
, ('E', 'European Climate Assessment and Dataset (Klein Tank et al., 2002)')
, ('F', 'U.S. Fort data ')
, ('G', 'Official Global Climate Observing System (GCOS) or other government-supplied data')
, ('H', 'High Plains Regional Climate Center real-time data')
, ('I', 'International collection (non U.S. data received through personal contacts)')
, ('K', 'U.S. Cooperative Summary of the Day data digitized from paper observer forms (from 2011 to present)')
, ('M', 'Monthly METAR Extract (additional ASOS data)')
, ('N', 'Community Collaborative Rain, Hail,and Snow (CoCoRaHS)')
, ('Q', 'Data from several African countries that had been "quarantined", that is, withheld from public release until permission was granted from the respective meteorological services')
, ('R', 'NCEI Reference Network Database (Climate Reference Network and Regional Climate Reference Network)')
, ('r', 'All-Russian Research Institute of Hydrometeorological Information-World Data Center')
, ('S', 'Global Summary of the Day (NCDC DSI-9618) NOTE: "S" values are derived from hourly synoptic reports exchanged on the Global Telecommunications System (GTS).  Daily values derived in this fashion may differ significantly from "true" daily data, particularly for precipitation (i.e., use with caution).')
, ('s', 'China Meteorological Administration/National Meteorological Information Center/ Climatic Data Center (http://cdc.cma.gov.cn)')
, ('T', 'SNOwpack TELemtry (SNOTEL) data obtained from the U.S.  Department of Agriculture Natural Resources Conservation Service')
, ('U', 'Remote Automatic Weather Station (RAWS) data obtained from the Western Regional Climate Center')
, ('u', 'Ukraine update')
, ('W', 'WBAN/ASOS Summary of the Day from NCDC Integrated Surface Data (ISD)')
, ('X', 'U.S. First-Order Summary of the Day (NCDC DSI-3210)')
, ('Z', 'Datzilla official additions or replacements')
, ('z', 'Uzbekistan update')
;      
/* 
       When data are available for the same time from more than one source,
       the highest priority source is chosen according to the following
       priority order (from highest to lowest):
       Z,R,0,6,C,X,W,K,7,F,B,M,r,E,z,u,b,s,a,G,Q,I,A,N,T,U,H,S
*/

