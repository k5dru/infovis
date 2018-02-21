

/* 

data:  https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt

IV. FORMAT OF "ghcnd-stations.txt"

------------------------------
Variable   Columns   Type
------------------------------
ID            1-11   Character
LATITUDE     13-20   Real
LONGITUDE    22-30   Real
ELEVATION    32-37   Real
STATE        39-40   Character
NAME         42-71   Character
GSN FLAG     73-75   Character
HCN/CRN FLAG 77-79   Character
WMO ID       81-85   Character
------------------------------
*/ 

create table station (
ID char(11) primary key,
LATITUDE decimal,
LONGITUDE decimal,
ELEVATION decimal,
STATE varchar(2),
NAME  varchar(30),
GSN_FLAG varchar(3),
HCN_CRN_FLAG varchar(3),
WMO_ID  varchar(5)
);
