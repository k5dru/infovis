drop view if exists wspr_vw;

create view wspr_vw as
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
from wspr_stage w;

\d wspr_vw

select * from ( 
select w.*, row_number() over (partition by tx_call order by observationtime) as call_observation
from wspr_vw w 
where substr(rx_grid,1,4) = 'EM35'
) d 
where call_observation = 1 
order by observationtime
;


