psql -c '\copy wspr to stdout with CSV' | pv | lzop > wspr.lzo
