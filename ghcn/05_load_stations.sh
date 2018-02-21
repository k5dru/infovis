curl  https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt | 
awk '{print substr($0,1,11) "|" \
substr($0,13,8) "|" \
substr($0,22, 9) "|" \
substr($0,32,6) "|" \
substr($0,39,2) "|" \
substr($0,42,30) "|" \
substr($0,73,3) "|" \
substr($0,77,3) "|" \
substr($0,81,5) }' | 
sed 's/  *|/|/g;s/|  */|/g' | 
sed 's/"/""/g' |
psql -c "\\copy station from stdin with CSV delimiter '|'"
