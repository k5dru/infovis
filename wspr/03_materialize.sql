
\d+
\di+
drop table WSPR;
/* was 3923MB, is now 3203 after data type changes */
create table wspr as select * from wspr_vw /* order by timestamp */;
\d+
/* index is 665MB */
create index wspr_timestamp_idx on wspr(observationtime);
\di+
