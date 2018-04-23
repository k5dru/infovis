/* replacement, hopefully better, for the previous batch sql. 

   However it is taking FAR longer than the old one.  

   first time though, this will take maybe 20 minutes. 
   Then, run it in a loop until it doesn't do anything anymore. 
   For example: 
   while sleep 1; do time psql < 03.2_batch.sql; done

   This will eventually output a very quick message stating that 
   everything already exists and nothing was inserted: 

Timing is on.
ALTER SYSTEM
Time: 0.412 ms
ALTER SYSTEM
Time: 1.440 ms
ERROR:  relation "rx_moving" already exists
Time: 4.329 ms
ERROR:  relation "tx_moving" already exists
Time: 1.257 ms
ERROR:  relation "wspr" already exists
Time: 3.316 ms
ERROR:  relation "wspr_timestamp_idx" already exists
Time: 0.403 ms
INSERT 0 0
Time: 6.994 ms

   That INSERT 0 0 means it is time to stop. 
*/

\timing 
alter system set work_mem='100MB';      /* not so small that a jillion sort segments are created */
alter system set shared_buffers='10MB'; /* not too large since OS cache is faster */ 

/* the set of rx stations with moving locations */ 
create table rx_moving as select rx_call
from wspr_vw
group by rx_call
having min(rx_grid) != max(rx_grid);

create table tx_moving as select tx_call
from wspr_vw
group by tx_call
having min(tx_grid) != max(tx_grid);

/* the vast majority of stations don't move.  
   Just move all their observations into the permanent table. */ 

/* this takes about 11 minutes:  */
create table wspr as 
select wspr_vw.* from wspr_vw
where rx_call not in (select rx_call from rx_moving) 
and   tx_call not in (select tx_call from tx_moving); 


create index wspr_timestamp_idx on wspr(observationtime);

with batch_times as ( 
  select batch_begin_time, 
  batch_begin_time + interval '4 hour' as batch_end_time
  from ( 
    select coalesce(max(observationtime) + interval '1 minute', '2017-11-30 23:00 -00'::timestamp with time zone ) as batch_begin_time 
    from wspr 
    where (
      rx_call in (select rx_call from rx_moving  ) 
      or   tx_call in (select tx_call from tx_moving )
    )
  ) bg
)
select * from batch_times; 


insert into wspr
/* select the entire set of rows from wspr_vw with moving TX or RX locations */ 
with batch_times as ( 
  select batch_begin_time, 
  batch_begin_time + interval '4 hour' as batch_end_time
  from ( 
    select coalesce(max(observationtime) + interval '1 minute', '2017-11-30 23:00 -00'::timestamp with time zone ) as batch_begin_time 
    from wspr 
    where (
      rx_call in (select rx_call from rx_moving  ) 
      or   tx_call in (select tx_call from tx_moving )
    )
  ) bg
)
,tx_lat_avg as ( 
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
  from wspr_vw
  where (
    rx_call in (select rx_call from rx_moving ) 
    or   tx_call in (select tx_call from tx_moving )
  )
  and observationtime between (select batch_begin_time from batch_times) and (select batch_end_time from batch_times)
)
-- now I really want only one value per station per observationtime, so I'll take the average of the calculated ones above, and fall back to the original calculation if that doesn't exist.
select observationtime 
,coalesce(avg(new_tx_latitude) over (partition by tx_call /* collate "C" */ , observationtime), tx_latitude)::float4 as tx_latitude
,coalesce(avg(new_tx_longitude) over (partition by tx_call /* collate "C" */ , observationtime), tx_longitude)::float4 as tx_longitude
,coalesce(avg(new_rx_latitude) over (partition by rx_call /* collate "C" */ , observationtime), rx_latitude)::float4 as rx_latitude
,coalesce(avg(new_rx_longitude) over (partition by rx_call /* collate "C" */ , observationtime), rx_longitude)::float4 as rx_longitude
,tx_call
,tx_grid  -- I no longer care about actual grid, just best lat and lon.
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
from tx_lat_avg
;

