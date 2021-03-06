/* check for calls in my grid */ 

select * from ( 
select w.*, row_number() over (partition by tx_call order by observationtime) as call_observation
from wspr w 
where substr(rx_grid,1,4) = 'EM35'
) d 
where call_observation = 1 
order by observationtime
;


/* visualize clusters by hour, animated, https://guides.library.duke.edu/tableau/tableau_animated_map */
select
date_Trunc('DAY', observationtime) as utc_day,
date_trunc('HOUR', observationtime) as utc_hour,
substr(tx_grid, 1, 4) as tx_grid_prefix,
avg(tx_latitude) as avg_tx_latitude,
avg(tx_longitude) as avg_tx_longitude,
avg(distance_km) as avg_distance_km,
avg(frequency) as avg_frequency,
min(case when grid_frequency_ntile = 2 then frequency end) as ntile_2_min_frequency,
min(case when grid_frequency_ntile = 3 then frequency end) as ntile_3_min_frequency,
min(case when grid_frequency_ntile = 4 then frequency end) as ntile_4_min_frequency,
count(*)
from
(
  select wspr.*,
  ntile(4) over (partition by substr(tx_grid, 1, 4), date_trunc('HOUR', observationtime) order by frequency)
    as grid_frequency_ntile
  from wspr
  where observationtime between '2017-12-03 00:00' and '2017-12-03 23:59'
) wspr_ntile
group by 1,2,3
having count(*) > 3
order by 1,2;

/* what I really want to display, is what is
  the highest frequency
  of several observations
  of a quality signal
  where quality is defined by good reception (based on tx power) */

/* what is quality? (with apologies to ZATAOMM */

select quality_pctile, max(quality), avg(distance_km) as avg_km, avg(rx_snr) as avg_snr, avg(tx_dbm) as avg_dbm, count(*)
from (
  select quality,distance_km, rx_snr, tx_dbm,
   ntile(100) over (order by quality) as quality_pctile
   from (
    select
    distance_km, rx_snr, tx_dbm,
      /* give everyone 3db, divide receive SNR by xmit power, and multiply by km. */
    distance_km::float * ((rx_snr + 36)::float / (tx_dbm + 3)) as quality
      from wspr
    --where observationtime between '2017-12-03 00:00' and '2017-12-03 23:59'
  )data
) q
group by 1
order by 1;

/*
25th pctile is    367.
median quality is 668.
75th pctile is   1168.
99th is          4743.
*/

select avg(tx_latitude), avg(tx_longitude), avg(distance_km), quality_quartile, count(*)
from wspr 
group by quality_quartile;

select * from wspr where distance_km between 2100 and 2200 
limit 1000;

/* determine frequency distribution */ 
 select n, max(frequency) from ( select ntile(100) over (order by frequency) as n, frequency from (select frequency from  wspr) data ) datan group by n order by n;

/*  interesting results (remember this is December 2017 data) :

    10: 0.475
    11: 1.83 
    18: 3.57
about a third are under 5
    29: 5.28
    31: 7.04
    69: 10.14
about two thirds are under 10
    83: 14.09
    99: 21.09  
*/




/* group by TX prefix  */ 

select
substr(tx_call, 1, 2) as tx_prefix,
substr(rx_call, 1, 2) as rx_prefix,
max(observationtime) as observationtime, 
avg(tx_latitude) as tx_lat, 
avg(tx_longitude) as tx_lon, 
avg(rx_latitude) as rx_lat, 
avg(rx_longitude) as rx_lon,
--substr(tx_grid, 1, 2),
avg(distance_km) as avg_km,
avg(quality_quartile) as avg_q,
count(*), 
row_number() over (partition by substr(tx_call, 1, 2) order by avg(distance_km) desc)
from wspr
where quality_quartile = 4
and observationtime between '2017-12-24 18:00' and '2017-12-24 18:15'
group by 1,2; 

/* only allow the 5 highest quality observations per TX station per minute */
select  * 
from (
  select wspr.*, 
  row_number() over (partition by observationtime, tx_call order by quality desc)
  as quality_rank, 
  row_number() over (partition by observationtime, tx_call order by distance_km desc)
  as distance_rank, 
  count(*) over (partition by observationtime, tx_call) as tx_observation_count
  from wspr
  where observationtime between '2017-12-24 18:00' and '2017-12-24 18:15'
  and quality_quartile = 4
) ranked_observations
where 
distance_rank <= 5;

/* try grouping by tx grid -- this has potential */ 
select  * 
from (
  select wspr.*, 
  row_number() over (partition by observationtime, substr(tx_grid, 1, 2) order by quality desc)
  as quality_rank, 
  row_number() over (partition by observationtime, substr(tx_grid, 1, 2) order by distance_km desc)
  as distance_rank, 
  count(*) over (partition by observationtime, substr(tx_grid, 1, 2)) as grid_observation_count
  from wspr
  where observationtime between '2017-12-24 18:00' and '2017-12-24 18:15'
  and quality_quartile = 4
) ranked_observations
where 
distance_rank <= 5;


/* are some staions over-represented? */
select observationtime, tx_call, count(*) from wspr group by 1,2 having count(*) > 50 order by 3 desc, 2, 1;

/* holy crow; some stations are being reported dozens or hundreds of times per observation. 
   Find a way to limit to the best obverstations by station: */ 
select wspr.*, 
row_number() over (partition by observationtime, tx_call order by quality desc) as tx_rownum 
from wspr 
where observationtime between '2017-12-24 08:00' and '2017-12-24 08:05';

/* Stations with qval of 4 are heard on average 6 times, but max reports can be in the dozens. */ 
select observationtime, min(tx_observations), avg(tx_observations), max(tx_observations)
from (
  select observationtime, tx_call, max(tx_rownum) as tx_observations
  from (
    select wspr.observationtime, tx_call, rx_call, distance_km, quality, 
    row_number() over (partition by observationtime, tx_call order by quality desc) as tx_rownum 
    from wspr 
    where observationtime between '2017-12-24 08:00' and '2017-12-24 12:05'
    and quality_quartile = 4
  ) data 
  group by 1,2
  order by 1,2
) dat2
 group by 1
order by 1
;
