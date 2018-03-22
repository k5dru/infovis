
/* TODO:
 
 Sliders for:  
 done: minutes old observations
 done: update rate
 DONE: spin rate
 quality of observations 
 received strength of observations 
 
 filter for signals that are new, not seen in a few hours
 filter for signals that are just barely perceptable 
 different marks for really strong signals - maybe arrows or hashes or something. 
 done: distinguish midnight sun point from midday sun point
 more precise time control, with time spinner 
 done: identify transmitters by glyph
 
 done: sloppyarc vs. precisionarc.  Use sloppyarc for coastlines.
 
 Legend for drift or band.
 
 Done; didn't like: Consider this as a mechanism to indicate direction: 
 beginShape(LINES);
 stroke(0);
 vertex(x, y, z);
 stroke(200, 150);
 vertex(xb, yb, zb);
 endShape();
 
 Done: Need to add "setpos" method for slider, 
 
 Todo:  click-mouse-wheel should single-step through the data forwards or backwards. 
 
done:  Need controls for time, observation window, various filters (quality, country, etc.)
 
done:  Need controls for brightness/contrast
 
 DONE: Need booleans to turn on and off different features, such as coastline, greyline, etc.
 
 Need global text color, since I can't depend on the value of stroke or fill in a scrollbar
 
 Set km_per_pixel based on screen size, and use the fullscreen call to make the screen fullscreen
 
tried; doesn't matter:  normalize latitude not using a loop
 
DONE:  update value of endDate based on hs1.getPos(); 
 as a fraction between   pgsql.getString("min_observationtime") and getString("max_observationtime") ); 
 
Consider making arcs "PSHape" objects 
Consider making coastline a "PShape" object instead of setting up each frame
  except can't call translate or rotate from within a shape object? 
 
 */


// current viewpoint to rotate to
float viewpointX = radians(-35); // PI / 6;  /* have to start somewhere */
float viewpointY = radians(92); // PI / 6;
// where was the mouse previously
float prevMouseX = 0, prevMouseY = 0;

float earthRadius = 6371.0; /* km */

float kmPerPixel = 20 ; /* 15 is realistic minium, 30 is realistic maximum */

float prevKmPerPixel = kmPerPixel; /* to know when this has changed */




void settings()
{ 
  size(1280, 850, P3D);
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


/* from here: https://forum.processing.org/two/discussion/13500/applying-a-texture-to-a-sphere */
PImage earth; 
PShape globe;

void setupGlobe() { 
  fill(255); 
  noStroke();
  String image_url;
  /* from here: https://forum.processing.org/two/discussion/13500/applying-a-texture-to-a-sphere */
  image_url="world32k.jpg"; // low-res sample file in processing examples 
  //image_url="https://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57752/land_shallow_topo_2048.jpg";
  image_url="land_shallow_topo_2048.jpg";  // from https://visibleearth.nasa.gov/view.php?id=57752
  image_url = "Political_Map_Pat_50pct.jpg";  // free from http://www.shadedrelief.com/political/Political_Map_Pat.jpg
  image_url="world.topo.bathy.200412.3x5400x2700.jpg"; // from https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73909/world.topo.bathy.200412.3x5400x2700.jpg
  
  
  earth = loadImage (image_url); 
  // this one isn't quiote right:  earth = loadImage ("http://worldmap.org.ua/Maps/World/Political_map_world_eng.jpg");
  //earth = loadImage("https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Whole_world_-_land_and_oceans_12000.jpg/1280px-Whole_world_-_land_and_oceans_12000.jpg");
  // out of heap space:  earth= loadImage("Whole_world_-_land_and_oceans_12000.jpg"); 
  noStroke(); 
  noFill(); 
  sphereDetail(90);

  globe = createShape(SPHERE, earthRadius / kmPerPixel); 

  globe.setTexture(earth);
}

void setup() {
  background(0);

  setupGlobe();

  setupControls(); 

  setupDatabase();

  setupCoastline();

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
    stroke(128, 128, 128);
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
    stroke(128, 128, 128);
    strokeWeight(2);   
    fill(128, 128, 128);
    translate(0, 0, ((earthRadius + 20) / kmPerPixel)); /* translate Z axis to 10km above surface*/
    //ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));

    drawGlyph(4); 

    noFill();
    text("D", (100 / kmPerPixel), - (100 / kmPerPixel));

    // OK that's pretty cool.  Paint an anti-sun on the other side of the earth to represent local midnight 
    stroke(128, 128, 128);
    strokeWeight(2);   
    fill(128, 128, 128);
    translate(0, 0, -2 * ((earthRadius + 20) / kmPerPixel)); /* translate Z axis to 10km above surface*/
    //ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
    drawGlyph(5); 

    noFill();
    text("N", (100 / kmPerPixel), - (100 / kmPerPixel));

    /* can I overwite with a transparant one to make it a little moon? 
     fill(128,128,128, 0);
     ellipse (0, 0, (200 / kmPerPixel), (200 / kmPerPixel));
     no, I can't. the other one just shows under it. 
     */
  }

  /* fill(10, 10, 120); 10, 10, 120 is my guess of earth blue, or my guess at it at least */
  //fill(10, 10, 64); 
  //  noFill();

  float lightValue = lightBright.getValue() * 255;
  if (sunPointButton.getState()) { 
    /* the sun is 149.6 million km from the earth; set light point appropriately far */
    translate(0, 0, ((149.6 * 1000000) / kmPerPixel)); /* translate Z axis */
    fill(32, 32, 128);
    float f = lightBright.getValue() * 255; 
    pointLight(lightValue, lightValue, lightValue, 0, 0, 0);
    ambientLight(0, 0, 0);
  } else
  {
    ambientLight(lightValue, lightValue, lightValue);
    pointLight(0, 0, 0, 0, 0, 0);
    fill(32, 32, 128);
  }

  popMatrix(); 


  if (coastlineButton.getState() == false) 
    stroke(0, 0, 255, 80);
  else
    noStroke();

  /* working way to make a blue ball: 
   sphereDetail(90); // number? amount? of tessellated triangles 
   sphere (earthRadius / kmPerPixel);
   */

  /* if kmPerPixel has changed, we need to setup the globe again. */
  if (kmPerPixel != prevKmPerPixel) { 
    prevKmPerPixel = kmPerPixel; 
    setupGlobe();
  }
  rotateY(radians(90)); 
  shape(globe);
  rotateY(radians(-90)); 

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

  text("Scale: " + kmPerPixel + "km/pixel", textX, (textY += textYInc));

  return;
}

int last_load_millis = 0;
int last_spin_millis = 0; 

void draw() {
  background(0);
  //  strokeWeight(2); 
  kmPerPixel = round(( 30 - (zoom.getValue() * 20) ) * 10) / 10.0;  

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

    endDate = new Date(min_observationtime.getTime() + millisecondsIntoWindow);
    beginDate = new Date(endDate.getTime() - (1000 * 60) * (int) (observationWindow.getValue() * 15) );    
    thread("loadMarks");
  } else
  { 
    hs1.setValue( (float) (
      (double)(endDate.getTime() -  min_observationtime.getTime()) // milliseconds in observable window
      / 
      (double)(max_observationtime.getTime() -  min_observationtime.getTime()) // milliseconds in observable window
      ));
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
  if (showTextButton.getState())
    drawText();

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


  if (millis() > (last_load_millis + (int)(updateRate.getValue() * 1000)) && !loadingMarks ) {
    last_load_millis = millis(); 

    if (updateButton.getState() || marks == null)
    { 
      if (endDate.getTime() > max_observationtime.getTime())
      { 
        beginDate = min_observationtime;  
        endDate = min_observationtime;
      }
      /* increment input times to DB query by 2 minutes */
      beginDate = new Date(beginDate.getTime() + (int) (timePerUpdate.getValue() * 60) * (1000 * 60) );  // Java time is in milliseconds  
      endDate = new Date(beginDate.getTime() + (int) (observationWindow.getValue() * 15) * (1000 * 60) );   
      //     loadMarks(beginDate, endDate); // WSPR data is updated every 2 minutes per protocol. 
      thread("loadMarks");
    }
  }



  // With an array, we say balls.length, with an ArrayList, we say balls.size()
  // The length of an ArrayList is dynamic
  // Notice how we are looping through the ArrayList backwards
  // This is because we are deleting elements from the list  

  if (marks != null /* && showMarksButton.getState() */) { 
    for (int i = 0; i < marks.size(); i++) { 
      // An ArrayList doesn't know what it is storing so we have to cast the object coming out
      Mark mark = marks.get(i);
      mark.display();
    }
  }
}
