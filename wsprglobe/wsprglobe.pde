
/* TODO:

Sliders for:  
  minutes old observations
  update rate
  spin rate
  quality of observations 
  received strength of observations 

filter for signals that are new, not seen in a few hours
filter for signals that are just barely perceptable 
different marks for really strong signals - maybe arrows or hashes or something. 
distinguish midnight sun point from midday sun point
more precise time control, with time spinner 
identify transmitters by glyph

sloppyarc vs. precisionarc.  Use sloppyarc for coastlines.

Legend for drift or band.

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

DONE: Need booleans to turn on and off different features, such as coastline, greyline, etc.

Need global text color, since I can't depend on the value of stroke or fill in a scrollbar

Set km_per_pixel based on screen size, and use the fullscreen call to make the screen fullscreen

normalize latitude not using a loop

DONE:  update value of endDate based on hs1.getPos(); 
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
    
    strokeWeight(1); 
    earthArc(lat1, lon1, alt1, lat2, lon2, alt2); 
  }
}

ArrayList<Mark> marks;         // the list that will be displayed from always
ArrayList<Mark> newMarks;      // work list, to load then swap to the marks list
boolean loadingMarks = false;  // semaphore for loading the newMarks arraylist 

//void loadMarks(Date beginDate, Date endDate) {
 
void loadMarks() {

  if (loadingMarks) return;  // some other thread beat me to it. 
  loadingMarks = true;       // set the semaphore. TODO: use a proper semaphore method. 
  
  int startMillis = millis(); 

  print("### entering loadMarks("+ dateFormat.format(beginDate) + ","+ dateFormat.format(endDate) +") ... "); 
  newMarks = new ArrayList<Mark>();  /* what happens to the old one?  It's Java - presumably it gets "collected".  */

  pgsql.query(""
+"  select tx_latitude, tx_longitude, rx_latitude "
+" , rx_longitude, distance_km, quality_quartile, drift  "
+" , extract(MINUTES from ('" + dateFormat.format(endDate) + "'::timestamp - observationtime)) as observation_age"
+"  from wspr       "
+"  where observationtime between '" + dateFormat.format(beginDate) + "'::timestamp"
+"                            and '" + dateFormat.format(endDate) + "'::timestamp"
+"  and quality_quartile = 4 and rx_snr < -18 "
//+"  order by random() limit 100           "
  );
     
  /* 1649 rows at '2017-12-14 06:08-06' */

  while ( pgsql.next() )
  {
    newMarks.add(
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
    
  println (newMarks.size() + " marks loaded in " + (millis() - startMillis) + " ms"); 
  marks=newMarks; 
  loadingMarks = false;
  
}


/* for SimpleDateFormat, from http://www.java2s.com/Tutorial/Java/0040__Data-Type/SimpleDateFormat.htm */
import java.text.SimpleDateFormat;
import java.util.Date;
import java.text.ParseException;

import java.util.TimeZone;  // from https://beginnersbook.com/2013/05/java-date-timezone/

Date beginDate;
Date endDate;
SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");

Date min_observationtime;
Date max_observationtime;

void setup() {
  background(255);

  setupControls(); 

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
    beginDate = dateFormat.parse("2017-12-01 08:48:00 -0000");  /* many marks at this time */
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
  if (greylineButton.getState() == true) 
  {
    stroke(128,128,128);
    strokeWeight(8); 
    noFill();
    ellipseMode(CENTER);
//    translate(0, 0, (-50 / kmPerPixel)); /* translate Z axis to 10km above surface*/
    ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));
//    translate(0, 0, (+100 / kmPerPixel)); /* translate Z axis to 10km above surface*/
//    ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));
 //   translate(0, 0, (-50 / kmPerPixel)); /* translate Z axis to 10km above surface*/
//    ellipse (0, 0, ((earthRadius * 2 + 100) / kmPerPixel), ((earthRadius * 2 + 100) / kmPerPixel));

    /* plop a pseudo-sun above the earth */
    stroke(128,128,128);
    strokeWeight(2);   
    fill(128,128,128);
    
    translate(0, 0, ((earthRadius + 20) / kmPerPixel)); /* translate Z axis to 10km above surface*/

    ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
    
    // OK that's pretty cool.  Paint an anti-sun on the other side of the earth to represent local midnight 
    translate(0, 0, -2 * ((earthRadius + 20) / kmPerPixel)); /* translate Z axis to 10km above surface*/
    ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
    
    /* can I overwite with a transparant one to make it a little moon? 
    fill(128,128,128, 0);
    ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
    no, I can't. the other one just shows under it. 
    */
  }
  
  /* fill(10, 10, 120); 10, 10, 120 is my guess of earth blue, or my guess at it at least */
  //fill(10, 10, 64); 
  //  noFill();

  if (sunPointButton.getState()) { 
    /* the sun is 149.6 million km from the earth; set light point appropriately far */
    translate(0, 0, ((149.6 * 1000000) / kmPerPixel)); /* translate Z axis */
    fill(32, 32, 128);
    pointLight(255, 255, 255, 0, 0, 0);
  }
  else
  {
    fill(32, 32, 128);
  }
  
  popMatrix(); 

  
  if (coastlineButton.getState() == false) 
    stroke(0, 0, 255, 80);
  else
    noStroke();

  sphereDetail(90); /* number? amount? of tessellated triangles */

  // sphere(height / 2 * 0.40);
  sphere (earthRadius / kmPerPixel);

    
  /* try to mark the poles */
  fill(20);  
  stroke(255, 0, 0); 
  //earthPoint(90.0, 0, 300); earthPoint(90.0, 0, 600); earthPoint(90.0, 0, 900);
  fastArc(90, 0, 0, 90, 0, 3000);
  stroke(0, 0, 255);
  //earthPoint(-90.0, 0, 300); earthPoint(-90.0, 0, 600); earthPoint(-90.0, 0, 900);
  fastArc(-90, 0, 0, -90, 0, 3000);

  if (coastlineButton.getState() == false) 
    return;


  /* mark the equator and +45 degrees north */
  stroke(0, 180, 0, 128 * coastBright.getValue());

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
      fastArc(lat, lon, 0, lat, lon+10, 0); 

  /* mark the maridians   
  for (int lon = -170; lon <= 180; lon += 10)  
    earthArc(-90, lon, 0, 90, lon, 0);
  */ 
  /* better, mark each hour, which is every 15 degrees */
  for (int lon = -165; lon <= 180; lon += 15)  
    fastArc(-90, lon, 0, 90, lon, 0);
  
  stroke(0, 180, 0, 256 * coastBright.getValue());
  
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
  
  if (marks != null) { 
    text(marks.size() + " marks", textX, (textY += textYInc));
  }
  
  return;
}

int last_load_millis = 0;
int last_spin_millis = 0; 

void draw() {
  background(0);
  strokeWeight(2); 

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

  
  updateControls(); 

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
  if (showTextButton.getState()) drawText();
  
  translate(width/2, height/2, 0);  // aha! This makes our drawing coordiate system zero-in-the-middle
  rotateX(viewpointX);
  rotateY(viewpointY);

  if (spinButton.getState()) 
  { 
    viewpointY += ((millis() - last_spin_millis) / 2000.0) * (spinRate.getValue() - 0.5);
  }
  
  last_spin_millis = millis(); 
  //0.01; 
   
  // set sun position based on time.  What time is it anyway? 
  
  
  //rotateZ(radians(23.4)); //earth is tilted 23 degrees 
  drawGlobe();
  

  if (millis() > (last_load_millis + 100) && !loadingMarks ) {
    last_load_millis = millis(); 

    if (updateButton.getState() || marks == null)
    { 
      /* increment input times to DB query by 2 minutes */
      beginDate = new Date(beginDate.getTime() + 2 * (1000 * 60) );  // Java time is in milliseconds  
      endDate = new Date(beginDate.getTime() + 5 * (1000 * 60) );   
 //     loadMarks(beginDate, endDate); // WSPR data is updated every 2 minutes per protocol. 
      thread("loadMarks"); 
    }  
  }



  // With an array, we say balls.length, with an ArrayList, we say balls.size()
  // The length of an ArrayList is dynamic
  // Notice how we are looping through the ArrayList backwards
  // This is because we are deleting elements from the list  

  if (marks != null && showMarksButton.getState()) { 
    for (int i = 0; i < marks.size(); i++) { 
      // An ArrayList doesn't know what it is storing so we have to cast the object coming out
      Mark mark = marks.get(i);
      mark.display();
    }
  }
   
}