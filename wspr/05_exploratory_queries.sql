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
