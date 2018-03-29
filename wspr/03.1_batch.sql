\timing 
alter system set work_mem='100MB';      /* not so small that a jillion sort segments are created */
alter system set shared_buffers='10MB'; /* not too large since OS cache is faster */ 

/* well crap.  can't do it all at once, but can batch it in there.  
   The idea here is that there is only a weak relationship between observations over time, 
   we can break up our data into smaller time chunks to process. If we had a parallel 
   database this could be easier. 

   First time through, create an index.  subsequent runs will be much faster 
   and the index and table create statements will fail (ignore that). 

   Munge all the data into its final location with the command line: 
     while sleep 0.3; do psql < 03.1_batch.sql; done

*/ 

create table wspr (
 observationtime   timestamp with time zone  
, tx_latitude       real                      
, tx_longitude      real                      
, rx_latitude       real                      
, rx_longitude      real                      
, tx_call           character varying(12)     
, rx_call           character varying(12)     
, tx_dbm            smallint                  
, rx_snr            smallint                  
, distance_km       smallint
, frequency         real                      
, drift             smallint                  
, quality_quartile  smallint                  
);

create index wspr_timestamp_idx on wspr(observationtime);

-- drop index wspr_stage_unixtime_idx;
--create index wspr_stage_unixtime_idx on wspr_stage(unixtime);
create index wspr_stage_unixtime_idx on wspr_stage(to_timestamp((unixtime)::double precision) );

insert into wspr
with batch_times as ( 
  select batch_begin_time, 
  batch_begin_time + interval '1 hour' as batch_end_time
  from ( 
    select coalesce(max(observationtime) + interval '1 minute', '2017-11-30 23:00 -00'::timestamp with time zone ) as batch_begin_time 
    from wspr 
  ) bg
)
, latitude_decode as ( 
 select to_timestamp(unixtime) as observationtime, 
/* this doesn't appear quite right, for the 4 digit case, but it is close. */
case length(grid)
when 6 then round((ASCII(SUBSTR(grid,2,1))-65.0)*10.0 + (SUBSTR(grid,4,1))::numeric + (ASCII(SUBSTR(grid,6,1))-97.0)/24.0 + 1/48.0 - 90.0,6)::float4
when 4 then round((ASCII(SUBSTR(grid,2,1))-65.0)*10.0 + (SUBSTR(grid,4,1))::numeric + 1/48.0 - 90.0,6)::float4
end as tx_latitude, 
case length(grid) 
when 6 then round((ASCII(SUBSTR(grid,1,1))-65.0)*20.0 + (SUBSTR(grid,3,1))::numeric*2.0 + (ASCII(SUBSTR(grid,5,1))-97.0)/12.0 + 1/24.0 - 180.0 ,6)::float4
when 4 then round((ASCII(SUBSTR(grid,1,1))-65.0)*20.0 + (SUBSTR(grid,3,1))::numeric*2.0 + 1/24.0 - 180.0 ,6)::float4
end as tx_longitude,
case length(reporter_grid)
when 6 then round((ASCII(SUBSTR(reporter_grid,2,1))-65.0)*10.0 + (SUBSTR(reporter_grid,4,1))::numeric + (ASCII(SUBSTR(reporter_grid,6,1))-97.0)/24.0 + 1/48.0 - 90.0 ,6)::float4
when 4 then round((ASCII(SUBSTR(reporter_grid,2,1))-65.0)*10.0 + (SUBSTR(reporter_grid,4,1))::numeric + 1/48.0 - 90.0,6)::float4
end as rx_latitude, 
case length(reporter_grid) 
when 6 then round((ASCII(SUBSTR(reporter_grid,1,1))-65.0)*20.0 + (SUBSTR(reporter_grid,3,1))::numeric*2.0 + (ASCII(SUBSTR(reporter_grid,5,1))-97.0)/12.0 + 1/24.0 - 180.0 ,6)::float4
when 4 then round((ASCII(SUBSTR(reporter_grid,1,1))-65.0)*20.0 + (SUBSTR(reporter_grid,3,1))::numeric*2.0 + 1/24.0 - 180.0 ,6)::float4
end as rx_longitude
-- spot_id 
--  unixtime 
,callsign as tx_call
,grid as tx_grid
,reporter as rx_call
,reporter_grid as rx_grid
,distance_km 
,azimuth 
,power_dbm as tx_dbm
,snr as rx_snr
,frequency::float4
,drift 
-- band 
--,version  
-- code 
,round(distance_km::numeric * ((snr + 36)::numeric / (power_dbm + 3)),1)::real as quality
,case 
when distance_km::numeric * ((snr + 36)::numeric / (power_dbm + 3)) > 1168 then 4
when distance_km::numeric * ((snr + 36)::numeric / (power_dbm + 3)) > 668 then 3
when distance_km::numeric * ((snr + 36)::numeric / (power_dbm + 3)) > 367 then 2
else 1 end::smallint as quality_quartile
from wspr_stage w
where to_timestamp(unixtime)  between (select batch_begin_time from batch_times) 
                          and (select batch_end_time from batch_times) 
) 
, tx_lat_avg as ( 
-- update 2018-03-23: I've just observed that some TX stations move, and that TX grids 
-- are only as good as what is reported by receivers.
-- therefore if anyone reports a TX location with a 6-length grid, use that for every observation.
select
observationtime
,tx_latitude
,avg(case when length(tx_grid) = 6 then tx_latitude end) over (partition by tx_call /* collate "C" */ order by observationtime rows between 200 preceding and 200 following) as new_tx_latitude
,tx_longitude
,avg(case when length(tx_grid) = 6 then tx_longitude end) over (partition by tx_call /* collate "C" */  order by observationtime rows between 200 preceding and 200 following) as new_tx_longitude
,rx_latitude
,avg(case when length(rx_grid) = 6 then rx_latitude end) over (partition by rx_call /* collate "C" */  order by observationtime rows between 200 preceding and 200 following) as new_rx_latitude
,rx_longitude
,avg(case when length(rx_grid) = 6 then rx_longitude end) over (partition by rx_call /* collate "C" */  order by observationtime rows between 200 preceding and 200 following) as new_rx_longitude
,tx_call
,tx_grid
,rx_call
,rx_grid
,distance_km   
,azimuth    
,tx_dbm    
,rx_snr   
,frequency 
,drift    
,quality
,quality_quartile
from latitude_decode
)
-- now I really want only one value per station per observationtime, so I'll take the average of the calculated ones above, and fall back to the original calculation if that doesn't exist.
select observationtime 
,coalesce(avg(new_tx_latitude) over (partition by tx_call /* collate "C" */ , observationtime), tx_latitude)::float4 as tx_latitude
,coalesce(avg(new_tx_longitude) over (partition by tx_call /* collate "C" */ , observationtime), tx_longitude)::float4 as tx_longitude
,coalesce(avg(new_rx_latitude) over (partition by rx_call /* collate "C" */ , observationtime), rx_latitude)::float4 as rx_latitude
,coalesce(avg(new_rx_longitude) over (partition by rx_call /* collate "C" */ , observationtime), rx_longitude)::float4 as rx_longitude
,tx_call
-- ,tx_grid  -- I no longer care about actual grid, just best lat and lon.
,rx_call
-- ,rx_grid
,distance_km 
-- ,azimuth    
,tx_dbm    
,rx_snr   
,frequency 
,drift    
-- ,quality
,quality_quartile
from tx_lat_avg
;

select max(observationtime) from wspr;
