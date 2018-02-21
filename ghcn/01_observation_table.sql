/* prepare to load data from https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/ */ 

drop table observation;

create table observation ( 
  station_code char(11),
  observation_date date, 
  element char(4), 
  data_value integer,
  M_FLAG varchar(1), 
  Q_FLAG varchar(1),
  S_FLAG varchar(1),
  OBS_TIME varchar(4) 
);

alter table observation add constraint pk_observation primary key (element, station_code, observation_date);

comment on column observation.station_code is 'character station identification code';
comment on column observation.observation_date is '8 character date in YYYYMMDD format (e.g. 19860529 = May 29, 1986)';
comment on column observation.ELEMENT is '4 character indicator of element type';
comment on column observation.DATA_VALUE is '5 character data value for ELEMENT';
comment on column observation.M_FLAG is '1 character Measurement Flag';
comment on column observation.Q_FLAG is '1 character Quality Flag';
comment on column observation.S_FLAG is '1 character Source Flag';
comment on column observation.OBS_TIME is '4-character time of observation in hour-minute format (i.e. 0700 =7:00 am)';
