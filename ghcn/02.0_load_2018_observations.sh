curl https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/2018.csv.gz |
gzip -dc |
psql -c "\\copy observation from stdin with CSV"
