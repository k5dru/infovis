
MIN=0

(echo '\timing'; 
while [ $MIN -lt 44640 ]; do 
	echo "select current_timestamp, min(observationtime), max(observationtime), count(*), avg(tx_latitude), avg(rx_longitude)"
	echo "from wspr where wspr.observationtime "
	echo "between '2017-11-30 18:00'::timestamp + ($MIN * interval '1 minutes') "
	echo "and     '2017-11-30 18:00'::timestamp + ($MIN * interval '1 minutes') + interval '14 minutes';"
	
	MIN=$(($MIN + 15))
done) | psql


