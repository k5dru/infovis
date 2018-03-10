Data from http://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-coastline/
used https://geoconverter.hsr.ch/ to convert this to GeoJSON format, and 
used sed 's/\(\.[0-9]\{3\}\)[0-9]*/\1/g' ne_10m_coastline.geojson.orig > ne_10m_coastline_rp.geojson
to remove the digits that won't matter when plotted on a global scale anwyay. 
WARNING:  if you use this, be sure you know it is REDUCED PRECISION copy

