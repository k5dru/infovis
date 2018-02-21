-- from http://wsprnet.org/drupal/downloads

/* sample: 
995573647,1512086400,AA9GE,EN50gq,-25,10.140187,AD5GH,FN42hs,23,0,1515,267,10,,0
996276504,1512086400,JF3MKC,PM74xm,-11,7.040091,BH4BTZ,PM01,33,0,1438,72,7,0.8_r3058,0
996530500,1512086400,DL8HAF/P,JO53dm,-19,3.594157,DJ5AM,JO61wb,23,0,366,320,3,3.00_r2326,0
996530417,1512086400,DL8HAF/P,JO53dm,-20,3.594047,DL0PBS,JO33,17,0,220,87,3,3.00_r2326,0
996530434,1512086400,DL8HAF/P,JO53dm,-7,3.594118,G3SXH,IO80fr,30,0,992,66,3,3.00_r2326,0
*/ 

drop table if exists wspr_stage; 

create table wspr_stage (
Spot_ID integer 
,unixtime bigint
,Reporter varchar(12)
,Reporter_Grid varchar(6)
,SNR smallint
,Frequency decimal
,CallSign varchar(12)
,Grid varchar(6)
,Power_dBm smallint
,Drift smallint
,Distance_km smallint
,Azimuth smallint
,Band smallint
,Version varchar(12)
,Code smallint
); 

/*
Spot_ID A unique integer identifying the spot which otherwise carries no information. Used as primary key in the database table. Not all spot numbers exist, and the files may not be in spot number order
Timestamp The time of the spot in unix time() format (seconds since 1970-01-01 00:00 UTC). To convert to an excel date value, use =time_cell/86400+"1/1/70" and then format it as a date/time.
Reporter The station reporting the spot. Usually an amateur call sign, but several SWLs have participated using other identifiers. Maximum of 10 characters.
Reporter's Grid Maidenhead grid locator of the reporting station, in 4- or 6-character format.
SNR Signal to noise ratio in dB as reported by the receiving software. WSPR reports SNR referenced to a 2500 Hz bandwidth; typical values are -30 to +20dB.
Frequency Frequency of the received signal in MHz
Call Sign Call sign of the transmitting station. WSPR encoding of callsigns does not encode portable or other qualifying (slash) designators, so the call may not represent the true location of the transmitting station. Maximum of 6 characters.
Grid Maidenhead grid locator of transmitting station, in 4- or 6-character format.
Power Power, as reported by transmitting station in the transmission. Units are dBm (decibels relative to 1 milliwatt; 30dBm=1W). Typical values are 0-50dBm, though a few are negative (< 1 mW).
Drift The measured drift of the transmitted signal as seen by the receiver, in Hz/minute. Mostly of use to make the transmitting station aware of systematic drift of the transmitter. Typical values are -3 to 3.
Distance Approximate distance between transmitter and receiver along the great circle (short) path, in kilometers. Computed form the reported grid squares.
Azimuth Approximate direction, in degrees, from transmitting station to receiving station along the great circle (short) path.
Band Band of operation, computed from frequency as an index for faster retrieval. This may change in the future, but at the moment, it is just an integer representing the MHz component of the frequency with a special case for LF (-1: LF, 0: MF, 1: 160m, 3: 80m, 5: 60m, 7: 40m, 10: 30m, ...).
Version Version string of the WSPR software in use by the receiving station. May be bank, as versions were not reported until version 0.6 or 0.7, and version reporting is only done through the realtime upload interface (not the bulk upload).
Code Archives generated after 22 Dec 2010 have an additional integer Code field. Non-zero values will indicate that the spot is likely to be erroneous (bogus callsign, appears to be wrong band, appears to be an in-band mixing product, etc. When implemented, the specific codes will be documented here.

*/ 
