create table wspr as select * from wspr_vw order by timestamp;
create index wspr_timestamp_idx on wspr(timestamp);
