
/* TODO:
    Consider this as a mechanism to indicate direction: 
    beginShape(LINES);
    stroke(0);
    vertex(x, y, z);
    stroke(200, 150);
    vertex(xb, yb, zb);
    endShape();

Need to add "setpos" method for slider, 
  TOdo:  it appears to be setting "spos" but the slider is never changing position. Why? 
  
Todo:  click-mouse-wheel should single-step through the data forwards or backwards. 

Need controls for time, observation window, various filters (quality, country, etc.)

Need controls for brightness/contrast

Need booleans to turn on and off different features, such as coastline, greyline, etc.

Need global text color, since I can't depend on the value of stroke or fill in a scrollbar

Set km_per_pixel based on screen size, and use the fullscreen call to make the screen fullscreen

TODO:  update value of endDate based on hs1.getPos(); 
  as a fraction between   pgsql.getString("min_observationtime") and getString("max_observationtime") ); 



*/


// current viewpoint to rotate to
float viewpointX = radians(-35); // PI / 6;  /* have to start somewhere */
float viewpointY = radians(92); // PI / 6;
// where was the mouse previously
float prevMouseX = 0, prevMouseY = 0;

float earthRadius = 6371.0; /* km */

float kmPerPixel = 20 ; /* 15 is realistic minium, 30 is realistic maximum */  

JSONObject json_coastline;


/* database connection: */
import de.bezier.data.sql.*;    
PostgreSQL pgsql;
void settings()
{ 
  size(1280, 850, P3D);
  
}

/* https://processing.org/examples/arraylistclass.html */
class Mark {
  /* postition of endpoints */ 
  float lat1; 
  float lon1;
  float alt1;     //altitude of first point
  float lat2; 
  float lon2; 
  float alt2; 
  int quality_quartile;
  int drift;
  int observation_age;  int alpha;

  Mark(float a, float b, float c, float d, float e, float f, int g, int h, int i) { 
    lat1=a;
    lon1=b;
    alt1=c;
    lat2=d;
    lon2=e;
    alt2=f;
    quality_quartile = g;
    drift = h;
    observation_age = i;
    alpha=(64 - observation_age * 8) * 2;
    if (alpha < 0) {  
      alpha = 0; 
    }
  }
  
  void display() { 
    if (drift == 0) { 
      stroke(255,255,255, alpha);
    }
    if (drift < 0) { 
      stroke(0,255,255, alpha);
    }
    if (drift > 0) { 
      stroke(255,255,0, alpha);
    }
    
    earthArc(lat1, lon1, alt1, lat2, lon2, alt2); 
  }
}

ArrayList<Mark> marks;

void loadMarks(Date beginDate, Date endDate) {
  int startMillis = millis(); 
  print("### entering loadMarks("+ dateFormat.format(beginDate) + ","+ dateFormat.format(endDate) +") ... "); 
  marks = new ArrayList<Mark>();  /* what happens to the old one?  It's Java - presumably it gets "collected".  */

  pgsql.query(""
+"  select tx_latitude, tx_longitude, rx_latitude "
+" , rx_longitude, distance_km, quality_quartile, drift  "
+" , extract(MINUTES from ('" + dateFormat.format(endDate) + "'::timestamp - observationtime)) as observation_age"
+"  from wspr       "
+"  where observationtime between '" + dateFormat.format(beginDate) + "'::timestamp"
+"                            and '" + dateFormat.format(endDate) + "'::timestamp"
+"  and quality_quartile = 4    "
+"  limit 10000           "
  );
     
  /* 1649 rows at '2017-12-14 06:08-06' */

  while ( pgsql.next() )
  {
    marks.add(
      new Mark( 
        pgsql.getFloat("tx_latitude"), 
        pgsql.getFloat("tx_longitude"), 
        pgsql.getFloat("quality_quartile") * 250,  /* altitude 1 */
        pgsql.getFloat("rx_latitude"), 
        pgsql.getFloat("rx_longitude"), 
        0, /* altitude 2 */ 
        pgsql.getInt("quality_quartile"), 
        pgsql.getInt("drift"), 
        pgsql.getInt("observation_age")
      )
    );
  }
    
  println (marks.size() + " marks loaded in " + (millis() - startMillis) + " ms"); 
   
}


/* for SimpleDateFormat, from http://www.java2s.com/Tutorial/Java/0040__Data-Type/SimpleDateFormat.htm */
import java.text.SimpleDateFormat;
import java.util.Date;
import java.text.ParseException;

import java.util.TimeZone;  // from https://beginnersbook.com/2013/05/java-date-timezone/

Date beginDate;
Date endDate;
SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");

HScrollbar hs1;  // One scrollbars

Date min_observationtime;
Date max_observationtime;

void setup() {
  background(255);

/* float xposition, float yposition, int swidth, int sheight, int lethargy */ 
  hs1 = new HScrollbar(0, height-9, width, 16, 1);

  /* thanks to  fjenett 20081129 */
  /* make database connection */
  String user     = "lemley";
  String pass     = "InfoVisIsAwesome";

  // name of the database to use
  //
  String database = "lemley";

  // connect to database on "localhost"
  //
  pgsql = new PostgreSQL( this, "localhost", database, user, pass );

  // connected?
  if ( pgsql.connect() )
  {

    // now let's query for last 10 entries in "weather"
    pgsql.query( "SELECT * FROM wspr limit 2" );

    // anything found?
    while ( pgsql.next() )
    {
      println(" *** new row *** "); 
      // splendid, here's what we've found ..
      println( pgsql.getString("observationtime") );  //| timestamp with time zone | 
      println( pgsql.getTimestamp("observationtime") );  //| timestamp with time zone | 
      println( pgsql.getFloat("tx_latitude") );      //| real                     | 
      println( pgsql.getFloat("tx_longitude") );     //| real                     | 
      println( pgsql.getFloat("rx_latitude") );      //| real                     | 
      println( pgsql.getFloat("rx_longitude") );     //| real                     | 
      println( pgsql.getString("tx_call") );          //| character varying(12)    | 
      println( pgsql.getString("tx_grid") );          //| character varying(6)     | 
      println( pgsql.getString("rx_call") );          //| character varying(12)    | 
      println( pgsql.getString("rx_grid") );          //| character varying(6)     | 
      println( pgsql.getInt("distance_km") );      //| smallint                 | 
      println( pgsql.getInt("azimuth") );          //| smallint                 | 
      println( pgsql.getInt("tx_dbm") );           //| smallint                 | 
      println( pgsql.getInt("rx_snr") );           //| smallint                 | 
      println( pgsql.getFloat("frequency") );        //| real                     | 
      println( pgsql.getInt("drift") );            //| smallint                 | 
      println( pgsql.getFloat("quality") );          //| real                     | 
      println( pgsql.getInt("quality_quartile") ); //| smallint                 |
    }
  } else
  {
    // yay, connection failed !
    println ("postgresql connection failed.");
  }

  /* while we're in the data, get the min and max observation times */ 
  pgsql.query( "select min(observationtime) as min_observationtime, max(observationtime) as max_observationtime from wspr" );
  if ( pgsql.next() ) { 
      println( pgsql.getString("min_observationtime") );
      println( pgsql.getString("max_observationtime") ); 
  }

  /* using an actual date instead of minutes-since-december-1 */
  try {
    beginDate = dateFormat.parse("2017-11-30 18:00:00 -0600");
//    min_observationtime = dateFormat.parse(pgsql.getString("min_observationtime"));
//    max_observationtime = dateFormat.parse(pgsql.getString("max_observationtime"));
    min_observationtime = dateFormat.parse("2017-11-30 18:00:00 -0600");
    max_observationtime = dateFormat.parse("2017-12-31 18:00:00 -0600");
    println(beginDate);
    println(dateFormat.format(beginDate));
    endDate = new Date(beginDate.getTime() + 5 * (1000 * 60) );  /* time is in milliseconds */ 
    println(dateFormat.format(endDate));
  } catch (ParseException e) {
    e.printStackTrace();
  }




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
  /* with thanks to https://forum.processing.org/one/topic/how-to-read-geojson-data.html */ 
  JSONArray coasts = json_coastline.getJSONArray("features"); 
  for (int i = 0; i < coasts.size(); i++) { 
     String coasttype = (coasts.getJSONObject(i).getJSONObject("geometry").getString("type"));
     JSONArray coastdata = coasts.getJSONObject(i).getJSONObject("geometry").getJSONArray("coordinates");
     for (int j = 0; j < coastdata.size(); j+=50) { 
        /* note:  i am using every 50th point, because it is far too slow for me to graph every point. */
       if ( coasttype.equals("LineString") && j > 0) { 
          //println (" latitude line from  " + coastdata.getJSONArray(j-1).getDouble(0) + " to " + coastdata.getJSONArray(j).getDouble(0));
          earthArc(coastdata.getJSONArray(j-50).getFloat(1), coastdata.getJSONArray(j-50).getFloat(0), (float) 0, 
                   coastdata.getJSONArray(j).getFloat(1), coastdata.getJSONArray(j).getFloat(0), (float) 0);
          //earthPoint(coastdata.getJSONArray(j).getFloat(1), coastdata.getJSONArray(j).getFloat(0), (float) 0);        
       }
       
/* the boundry set hat MultiLineString; this is what I did with that set:        
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


void drawGlobe()
{ 
  /* 
   lemley
   
   My plan was to draw a wireframe globe representing meridian and latitude lines, but
   this nifty sphere is built-in.  So to save quite a lot of time, I'm using the builtin. 
   Reference from here: https://processing.org/reference/sphereDetail_.html */

  /* The ionosphere is a shell of electrons and electrically charged atoms and molecules that surrounds the Earth, 
   stretching from a height of about 50 km (31 mi) to more than 1,000 km (620 mi).
   The F layer is about 300km in altitude */
//  lights(); 
  
  pushMatrix(); 
  
  /* NEW:  based on the timestamp endDate, which is the window end for the most recent observation, 
     locate the point on the Earth where the Sun would be straight up and put a mark there. */ 
  /* which would be local noon. */

  /* okay.   
    Formulas to rotate the globe under the sun point, given the UTC time.
    I sussed these out with a calculator.  They are probably crap, but they work.
    James  */
  SimpleDateFormat currentFormat = new SimpleDateFormat("D");
  currentFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
  int utc_dayofyear = Integer.parseInt(currentFormat.format(endDate));
  
  currentFormat = new SimpleDateFormat("HH");
  currentFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
  int utc_hours = Integer.parseInt(currentFormat.format(endDate));
  
  currentFormat = new SimpleDateFormat("mm");
  currentFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
  int utc_minutes = Integer.parseInt(currentFormat.format(endDate));

  //println(utc_dayofyear + " | " + utc_hours + " | " + utc_minutes);
  
  rotateY( (PI) + ((1 - ((utc_hours * 60.0 + utc_minutes)/1440.0) ) * PI * 2 )); /* must do Y axis first  */

  rotateX( radians(cos( (2 * PI * (utc_dayofyear)/365.0) + (2 * PI * 9/365.0) ) * -23.5) ); 
  
  /* Say, while I am here, can I put a circle around the world to indicate the grey line? */ 
  stroke(128,128,128);
  fill(128,128,128);
  //noFill();
  ellipseMode(CENTER);
  translate(0, 0, (-50 / kmPerPixel)); /* translate Z axis to 10km above surface*/
  ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));
  translate(0, 0, (+100 / kmPerPixel)); /* translate Z axis to 10km above surface*/
  ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));
  translate(0, 0, (-50 / kmPerPixel)); /* translate Z axis to 10km above surface*/
  ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));
  
  translate(0, 0, ((earthRadius + 10) / kmPerPixel)); /* translate Z axis to 10km above surface*/
  /* plop a pseudo-sun above the earth */
  noStroke();
  fill(128,128,128);
  ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));

// OK that's pretty cool.  Paint an anti-sun on the other side of the earth to represent local midnight 
  translate(0, 0, -2 * ((earthRadius + 10) / kmPerPixel)); /* translate Z axis to 10km above surface*/
  ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));

/* can I overwite with a transparant one to make it a little moon? 
  fill(128,128,128, 0);
  ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
  no, I can't. the other one just shows under it. 
*/

  
  /* the sun is 149.6 million km from the earth; set light point appropriately far */
  translate(0, 0, ((149.6 * 1000000) / kmPerPixel)); /* translate Z axis */

  /* fill(10, 10, 120); 10, 10, 120 is my guess of earth blue, or my guess at it at least */
  fill(10, 10, 64); 
  fill(32, 32, 128);
  //  noFill();

  pointLight(255, 255, 255, 0, 0, 0);
  popMatrix(); 
  
  //stroke(0, 0, 255, 80);
  sphereDetail(90); /* number? amount? of tessellated triangles */

  // sphere(height / 2 * 0.40);
  sphere (earthRadius / kmPerPixel);

  /* try to mark the poles */
  fill(20);  
  stroke(255, 0, 0); 
  //earthPoint(90.0, 0, 300); earthPoint(90.0, 0, 600); earthPoint(90.0, 0, 900);
  earthArc(90, 0, 0, 90, 0, 3000);
  stroke(0, 0, 255);
  //earthPoint(-90.0, 0, 300); earthPoint(-90.0, 0, 600); earthPoint(-90.0, 0, 900);
  earthArc(-90, 0, 0, -90, 0, 3000);

  /* mark the equator and +45 degrees north */
  stroke(0, 180, 0, 64);

  /* mark the latitude lines 
   for (int lat = -80; lat <= 80; lat += 10)
   for (int lon = -180; lon < 180; lon += 2)  
   earthPoint(lat, lon, 0); 
   
  /* mark the maridians  
   for (int lat = -90; lat < 90; lat += 2)
   for (int lon = -180; lon <= 180; lon += 10)  
   earthPoint(lat, lon, 0); 
   */

  /* do the same thing with earthArc */
  /* mark the latitude lines 
   */
  for (int lat = -80; lat <= 80; lat += 10)
    for (int lon = -180; lon < 180; lon += 10)  
      earthArc(lat, lon, 0, lat, lon+10, 0); 

  /* mark the maridians  
   */
  for (int lon = -170; lon <= 180; lon += 10)  
    earthArc(-90, lon, 0, 90, lon, 0); 
  
  stroke(0, 180, 0, 128);
  drawCoastline();
  
}

void drawText() 
{ 
  fill (255, 192, 0);  /* like old amber screens */ 
  
  int textX = 10;
  int textY = 0; 
  int textYInc = 15; 
  textAlign(LEFT);
  
  dateFormat.setTimeZone(TimeZone.getTimeZone("Pacific/Midway"));
  text(dateFormat.format(endDate) + " - Pacific/Midway", textX, (textY += textYInc));

  dateFormat.setTimeZone(TimeZone.getTimeZone("America/Chicago"));
  text(dateFormat.format(endDate) + " - America/Chicago", textX, (textY += textYInc));

  dateFormat.setTimeZone(TimeZone.getTimeZone("Europe/Luxembourg"));
  text(dateFormat.format(endDate) + " - Europe/Luxembourg", textX, (textY += textYInc));
    
  dateFormat.setTimeZone(TimeZone.getTimeZone("Asia/Tokyo"));
  text(dateFormat.format(endDate) + " - Asia/Tokyo", textX, (textY += textYInc));
  
  dateFormat.setTimeZone(TimeZone.getTimeZone("Australia/Sydney"));
  text(dateFormat.format(endDate) + " - Australia/Sydney", textX, (textY += textYInc) );

  dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
  
  
  textAlign(RIGHT);
  textX = width - 10;
  textY = 0; 
  
  text(mouseX + "," + mouseY, textX, (textY += textYInc)); 
  
  //if (frameCount % 10 == 0) println(frameRate + " FPS");
  text((int) frameRate + " FPS", textX, (textY += textYInc));
  
  text("hs1.getPos() = " + hs1.getPos(), textX, (textY += textYInc));
  
  
  return;
}

void earthPoint(float latitude, float longitude, float altitude)
{ 
  /* challenge:  Draw something at a particular latitude, longitude, and altitude in km. */
  pushMatrix(); 
  rotateY( radians(longitude) ); /* must do Y axis first  */

  rotateX( radians(latitude) );
  translate(0, 0, ((earthRadius + altitude)/ kmPerPixel)); /* translate Z axis */
  //sphereDetail(8);
  //sphere(5); 
  // box(2);
  line(0, 0, 0, 0, 0, 40 / kmPerPixel); /* x1, y1, z1, x2, y2, z2 */

  /* an X, fast but kind of ugly
   {
   line(-1,-1,0,1,1,0);
   line(1,-1,0,-1,1,0);
   }
   */
  popMatrix();
}

int earthArcLevel = 0; /* recursive level tracking variable to prevent stack overflow because I am a psychology minor, not a math minor */

void earthArc(float latitude1, float longitude1, float altitude1, float latitude2, float longitude2, float altitude2)
{
  /* THIS IS BROKEN in many ways (but is working for a proof-of-concept)
   FIXED: Need to find the great circle midpoint instead of the rectangular midpoint 
   FIXED? Need to cross the -179 to 1 longitude path the short way 
   FIXED: The lines are drawn crooked but it still looks pretty cool
   FIXED: Altitude 2 is not considered
   TODO:  Could use the cosine lookup table for performance
   FIXED: There are 111 km per degree at the surface.  What at an altitude of 1500 miles? 
   */
  /* is there a midpoint between there and here? */
  float midlat /* = (latitude1 + 90) + ((latitude2 + 90) - (latitude1 + 90)) / 2.0 - 90 */; 
  float midlon /* = (longitude1 + 180) + ((longitude2 + 180) - (longitude1 + 180)) / 2.0 - 180 */;
  float midalt = (altitude2 + altitude1) / 2.0;

  /* from https://www.movable-type.co.uk/scripts/latlong.html : 
   lat_rad/lon_rad for lati­tude/longi­tude in radian  */
  double lat_rad1 = radians(latitude1);
  double lat_rad2 = radians(latitude2);
  double lon_rad1 = radians(longitude1);
  double lon_rad2 = radians(longitude2);
  double Bx = Math.cos(lat_rad2) * Math.cos(lon_rad2-lon_rad1);
  double By = Math.cos(lat_rad2) * Math.sin(lon_rad2-lon_rad1);
  double lat_rad3 = Math.atan2(Math.sin(lat_rad1) + Math.sin(lat_rad2), Math.sqrt( (Math.cos(lat_rad1)+Bx)*(Math.cos(lat_rad1)+Bx) + By*By ) );
  double lon_rad3 = lon_rad1 + Math.atan2(By, Math.cos(lat_rad1) + Bx);

  midlat=degrees((float)lat_rad3); 
  midlon=degrees((float)lon_rad3);

  while (midlon <= -180) midlon += 360; 
  while (midlon > 180) midlon -= 360;  

  /* TODO: change to haversine distance */

  if (  (
    abs(latitude2 - latitude1) < 3 
    && 
    (  
    abs(longitude2 - longitude1) < 3
    || abs((longitude2 + 360) - longitude1) < 3  /* this is not working :( */
    || abs(longitude2 - (longitude1 + 360)) < 3
    )
    ) ||  earthArcLevel > 7 /* avoid runaway */)
  {
    /* don't draw a line across the international date line, because it's just not working. :( */
    if (longitude2 > 170 && longitude1 < -170) return;
    if (longitude1 > 170 && longitude2 < -170) return;

    /* if the points are close in space, just draw a line, because the Earth is flat a short-range. */
    pushMatrix(); 
    rotateY( (float) lon_rad3 ); /* must do Y axis first, longitude  */

    rotateX( (float) lat_rad3 );    /* latitude */
    translate(0, 0, ((earthRadius + midalt)/ kmPerPixel)); /* translate Z axis */

    float km_per_degree_latitude = 111.0 * ((earthRadius + midalt) / earthRadius);
    float km_per_degree_longitude = 111.0 * ((earthRadius + midalt) / earthRadius) * (float) Math.cos(lat_rad3);

    /* stroke(random(255)); */

    line(
      (longitude1 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude1) * km_per_degree_latitude / kmPerPixel, 
      (altitude1 - midalt) / kmPerPixel, 
      (longitude2 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude2) * km_per_degree_latitude / kmPerPixel, 
      (altitude2 - midalt) / kmPerPixel /* change this to just midalt for a cool effect */
    );

    popMatrix();
  } else /* not close enough for a straight line to look OK */
  { 
    /* just call myself twice with half the distance */
    earthArcLevel++;
    /* special case for the first call; go from ground level to space and back: 
       eh, turns out this isn't so cool after all. commented out.
    if (earthArcLevel == 1) 
    { 
    earthArc(latitude1, longitude1, 0, midlat, midlon, midalt); 
    earthArc(midlat, midlon, midalt, latitude2, longitude2, 0);
    } else {
    */
    earthArc(latitude1, longitude1, altitude1, midlat, midlon, midalt); 
    earthArc(midlat, midlon, midalt, latitude2, longitude2, altitude2);
    //}
    earthArcLevel--;
  }
}

int last_load_millis = 0;
int last_spin_millis = 0; 

void draw() {
  background(0);

  /* lemley:  make a function of mouseX and mouseY, when mousePressed */
  /* this changes ths global viewpoint.  */

  if (mousePressed &&   // check if in rough middle of screen 
    (mouseX > width * 0.25 && mouseX < width * 0.75) &&
    (mouseY > height * 0.25 && mouseY < height * 0.75)
    ) {
    /* OH VERY INTERESTING, this cuts out the back half of the visualization, even though I haven't 
     drawn any arcs yet.  Why?  */
    //    fill(20);  
    //    stroke(0); 
    //    rect( width * 0.25, height * 0.25, width * 0.5, height * 0.5);
    // viewpointX = (PI * 2) * ((width - (float)mouseY) / width);
    // viewpointY = (PI * 2) * ((width - (float)mouseX) / width);
    /* NEEDSWORK */
    viewpointX += ((prevMouseY - (float)mouseY) / width) * (PI * 2);
    viewpointY += (((float)mouseX - prevMouseX) / height) * (PI * 2);
  }
  /* save where mouse was, for next time through */
  prevMouseX = mouseX;
  prevMouseY = mouseY;
  
  /* if there was a mousewheel event, scale */
/* default: 
  camera(width/2.0,    //eyeX,
    height/2.0,        //eyeY,
    (height/2.0) / tan(PI*30.0 / 180.0), // eyeZ,
    width/2.0,         //centerX,
    height/2.0,        //centerY,
    0,                 //centerZ, 
    0,                 //upX, 
    1,                 // upY,
    0                  // upZ
    );
  */   

/* update controls that need updating */ 
  hs1.setNominalValue(dateFormat.format(endDate));
  
  hs1.update();
  hs1.display();
  
  if (mousePressed && mouseY > (height - 20))  /* TODO, and mouse is within the area of the control */ 
  { 
    long millisecondsIntoWindow = (long)(
        (max_observationtime.getTime() -  min_observationtime.getTime()) // milliseconds in observable window
        * (hs1.getPos() / (double) width)  // 0.0 to 1.0 depending on scrollbar position 
    ); 
    
    /* round off to minute */ 
    millisecondsIntoWindow /= 60000;
    millisecondsIntoWindow *= 60000;
 
    beginDate = new Date(min_observationtime.getTime() + millisecondsIntoWindow);
    endDate = new Date(beginDate.getTime() + 5 * (1000 * 60) );    
  } 
  else
  { 
    hs1.setPos( (float) (
        (double)(endDate.getTime() -  min_observationtime.getTime()) // milliseconds in observable window
        / 
        (double)(max_observationtime.getTime() -  min_observationtime.getTime()) // milliseconds in observable window
    ) * width); 
  }  
    
    
/* TODO:  update value of beginDate and endDate based on hs1.getPos(); 
  as a fraction between   pgsql.getString("min_observationtime") and getString("max_observationtime") ); 
   based on these fragments:  
   beginDate = dateFormat.parse("2017-11-30 18:00:00 -0600");
    min_observationtime = dateFormat.parse("2017-11-30 18:00:00 -0600");
    max_observationtime = dateFormat.parse("2017-12-31 18:00:00 -0600");
    println(beginDate);
    println(dateFormat.format(beginDate));
*/   
 

/* do any text processing before rotating the world. */
  drawText();
  
  translate(width/2, height/2, 0);  // aha! This makes our drawing coordiate system zero-in-the-middle
  rotateX(viewpointX);
  rotateY(viewpointY);
  viewpointY += ((millis() - last_spin_millis) / 30000.0); 
  last_spin_millis = millis(); 
  //0.01; 
   
  // set sun position based on time.  What time is it anyway? 
  
  
  //rotateZ(radians(23.4)); //earth is tilted 23 degrees 
  drawGlobe();
  

  if (millis() > (last_load_millis + 100) && !mousePressed ) {
    last_load_millis = millis(); 
 
    /* increment input times to DB query by 2 minutes */
    beginDate = new Date(beginDate.getTime() + 2 * (1000 * 60) );  // Java time is in milliseconds  
    endDate = new Date(beginDate.getTime() + 5 * (1000 * 60) );   

    loadMarks(beginDate, endDate); // WSPR data is updated every 2 minutes per protocol. 
  }



  // With an array, we say balls.length, with an ArrayList, we say balls.size()
  // The length of an ArrayList is dynamic
  // Notice how we are looping through the ArrayList backwards
  // This is because we are deleting elements from the list  


  for (int i = 0; i < marks.size(); i++) { 
    // An ArrayList doesn't know what it is storing so we have to cast the object coming out
    Mark mark = marks.get(i);
    mark.display();
  }
   
}