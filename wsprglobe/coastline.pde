JSONObject json_coastline;

void setupCoastline()
{
    // load JSON coastline, converted from ne_10m_admin_0_boundary_lines_land with https://geoconverter.hsr.ch/
  // bah, that's not the right one. 
  //json_coastline = loadJSONObject("ne_10m_admin_0_boundary_lines_land.geojson");
  json_coastline = loadJSONObject("ne_10m_coastline_rp.geojson");

  /* example data: 
   type": "FeatureCollection",
   "features": [
   type": "LineString", "coordinates": [ [ -124.758865926999945, 48.494017843000037 ], [ -124.582855997999928, 48.443917542000023 ], [ 
   type": "LineString", "coordinates": [ [ 11.437510613506703, 58.991720862705662 ], [ 11.400936726000083, 59.025907288000028 ], [ 11.3
   type": "MultiLineString", "coordinates": [ [ [ 8.394091838000094, 55.096328024000016 ], [ 8.452382853000131, 55.071471660000057 ], [
   */
}

void drawCoastline()
{ 
  strokeWeight(2);

  /* with thanks to https://forum.processing.org/one/topic/how-to-read-geojson-data.html */
  JSONArray coasts = json_coastline.getJSONArray("features"); 
  for (int i = 0; i < coasts.size(); i++) { 
    String coasttype = (coasts.getJSONObject(i).getJSONObject("geometry").getString("type"));
    JSONArray coastdata = coasts.getJSONObject(i).getJSONObject("geometry").getJSONArray("coordinates");
    for (int j = 0; j < coastdata.size(); j+=50) { 
      /* note:  i am using every 50th point, because it is far too slow for me to graph every point. */
      if ( coasttype.equals("LineString") && j > 0) { 
        //println (" latitude line from  " + coastdata.getJSONArray(j-1).getDouble(0) + " to " + coastdata.getJSONArray(j).getDouble(0));
        fastArc(coastdata.getJSONArray(j-50).getFloat(1), coastdata.getJSONArray(j-50).getFloat(0), (float) 0, 
          coastdata.getJSONArray(j).getFloat(1), coastdata.getJSONArray(j).getFloat(0), (float) 0);
        //earthPoint(coastdata.getJSONArray(j).getFloat(1), coastdata.getJSONArray(j).getFloat(0), (float) 0);
      }

      /* the boundry set has MultiLineString; this is what I did with that set:        
       if ( coasttype.equals("MultiLineString") ) { 
       //println (" latitude line from  " + coastdata.getJSONArray(j-1).getDouble(0) + " to " + coastdata.getJSONArray(j).getDouble(0));
       for (int k = 1; k < coastdata.getJSONArray(j).size(); k++) { 
       earthArc(coastdata.getJSONArray(j).getJSONArray(k-1).getFloat(1), coastdata.getJSONArray(j).getJSONArray(k-1).getFloat(0), (float) 0, 
       coastdata.getJSONArray(j).getJSONArray(k).getFloat(1), coastdata.getJSONArray(j).getJSONArray(k).getFloat(0), (float) 0);
       }         
       }
       */
    }
  }
} 
