# select current_timestamp, min(random_minute), count(*), avg(tx_latitude), avg(rx_longitude), min(timestamp), max(timestamp) from (select '2017-12-01 00:00'::timestamp + ((random() * 22320)::integer) * interval '2 minutes' as random_minute) r left join wspr on (wspr.timestamp between r.random_minute and r.random_minute + interval '15 minutes');

MIN=0

while [ $MIN -lt 44640 ]; do 
	echo "select current_timestamp, min(timestamp), max(timestamp), count(*), avg(tx_latitude), avg(rx_longitude)"
	echo "from wspr where wspr.timestamp "
	echo "between '2017-11-30 18:00'::timestamp + ($MIN * interval '1 minutes') "
	echo "and     '2017-11-30 18:00'::timestamp + ($MIN * interval '1 minutes') + interval '14 minutes';"
	
	MIN=$(($MIN + 15))
done


