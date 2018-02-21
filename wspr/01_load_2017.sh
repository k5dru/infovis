curl http://wsprnet.org/archive/wsprspots-2017-12.csv.gz | gzip -dc | 
psql -c "\\copy wspr_stage from stdin with CSV"
