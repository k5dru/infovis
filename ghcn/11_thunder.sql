select latitude, 
longitude,
elevation,
state,
count(*), 
count(distinct station_code) as station_count,
avg(data_value)
 from ghcn 
where element = 'WT03'
 and q_flag IS NULL 
group by 1,2,3,4
having count(*) > 10 
and avg(data_value) > 0.01
order by 2, 1 desc;
