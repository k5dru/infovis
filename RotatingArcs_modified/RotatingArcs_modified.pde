/**
 * Geometry 
 * by Marius Watz. 
 * 
 * Using sin/cos lookup tables, blends colors, and draws a series of 
 * rotating arcs on the screen.
*/
 
// Trig lookup tables borrowed from Toxi; cryptic but effective.
float sinLUT[];
float cosLUT[];
float SINCOS_PRECISION=1.0;
int SINCOS_LENGTH= int((360.0/SINCOS_PRECISION));
 
// System data
boolean dosave=false;
int num;
float pt[];
int style[];

// current viewpoint to rotate to
float viewpointX = PI / 6;  /* have to start somewhere, and this hides artifacts in the original demo */
float viewpointY = PI / 6;
// where was the mouse previously
float prevMouseX = 0, prevMouseY = 0;
 
float earthRadius = 6371.0; /* km */ 
float kmPerPixel = 20; 

void settings()
{ 
  size(1280, 900, P3D);
}

void setup() {
  background(255);
  
  // Fill the tables
  sinLUT=new float[SINCOS_LENGTH];
  cosLUT=new float[SINCOS_LENGTH];
  for (int i = 0; i < SINCOS_LENGTH; i++) {
    sinLUT[i]= (float)Math.sin(i*DEG_TO_RAD*SINCOS_PRECISION);
    cosLUT[i]= (float)Math.cos(i*DEG_TO_RAD*SINCOS_PRECISION);
  }
 
  num = 50;  /* number of arcs */ 
  pt = new float[6*num]; // rotx, roty, deg, rad, w, speed
  style = new int[2*num]; // color, render style
 
  // Set up arc shapes
  int index=0;
  float prob;
  for (int i=0; i<num; i++) {
    pt[index++] = random(PI*2); // Random X axis rotation
    pt[index++] = random(PI*2); // Random Y axis rotation
 
    pt[index++] = random(60,80); // Short to quarter-circle arcs
    if(random(100)>90) pt[index]=(int)random(8,27)*10;
 
    pt[index++] = int((earthRadius / kmPerPixel) + (random(50,600) / kmPerPixel)); // Radius. Space them out nicely
 
    pt[index++] = random(4,32); // Width of band
    if(random(100)>90) pt[index]=random(40,60); // Width of band
 
    pt[index++] = radians(random(5,30))/5; // Speed of rotation
 
    // get colors
    prob = random(100);
    if(prob<30) style[i*2]=colorBlended(random(1), 255,0,100, 255,0,0, 210);
    else if(prob<70) style[i*2]=colorBlended(random(1), 0,153,255, 170,225,255, 210);
    else if(prob<90) style[i*2]=colorBlended(random(1), 200,255,0, 150,255,0, 210);
    else style[i*2]=color(255,255,255, 220);

    if(prob<50) style[i*2]=colorBlended(random(1), 200,255,0, 50,120,0, 210);
    else if(prob<90) style[i*2]=colorBlended(random(1), 255,100,0, 255,255,0, 210);
    else style[i*2]=color(255,255,255, 220);

    style[i*2+1]=(int)(random(100))%3;
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
  lights(); 
  //stroke(0, 0, 255, 80);
  noStroke();
  /* fill(10, 10, 120); 10, 10, 120 is my guess of earth blue, or my guess at it at least */
  fill(20, 20, 160); 
//  noFill();
  sphereDetail(90); /* number? amount? of tessellated triangles */
  
  // sphere(height / 2 * 0.40);
 
  sphere (earthRadius / kmPerPixel); 
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
  line(0,0,0,0,0, 40 / kmPerPixel); /* x1, y1, z1, x2, y2, z2 */
 
    /* an X, fast but kind of ugly
    {
       line(-1,-1,0,1,1,0);
       line(1,-1,0,-1,1,0);
    }
    */
  popMatrix();
}

int earthArcLevel = 0; 

void earthArc(float latitude1, float longitude1, float altitude1, float latitude2, float longitude2, float altitude2)
{
  /* THIS IS BROKEN in many ways (but is working for a proof-of-concept)
  FIXED? Need to find the great circle midpoint instead of the rectangular midpoint 
  FIXED? Need to cross the -179 to 1 longitude path the short way 
  FIXED: The lines are drawn crooked but it still looks pretty cool
  FIXED: Altitude 2 is not considered
  Could use the cosine lookup table 
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
/*
  if (lat_rad1 == (double)0.00) lat_rad1 = 0.00000001;   
  if (lat_rad2 == (double)0.00 ) lat_rad2 = 0.00000001; 
  if (lon_rad1 == (double)0.00) lon_rad1 = 0.00000001; 
  if (lon_rad2 == (double) 0.00) lon_rad2 = 0.00000001; 
*/
  double Bx = Math.cos(lat_rad2) * Math.cos(lon_rad2-lon_rad1);
  double By = Math.cos(lat_rad2) * Math.sin(lon_rad2-lon_rad1);
/*
  if (Bx < (double)0.0000001) Bx = 0.0000001; // this fixes the grid lines going out into space... 
  if (By < (double)0.0000001) By = 0.0000001; 
  if (Bx > (double)PI * 2 - 0.0000001) Bx -= 0.0000001; // this fixes the grid lines going out into space... 
  if (By > (double)PI * 2 - 0.0000001) By -= 0.0000001; 
*/
  double lat_rad3 = Math.atan2(Math.sin(lat_rad1) + Math.sin(lat_rad2), Math.sqrt( (Math.cos(lat_rad1)+Bx)*(Math.cos(lat_rad1)+Bx) + By*By ) );
  double lon_rad3 = lon_rad1 + Math.atan2(By, Math.cos(lat_rad1) + Bx);

  /*
   while (lat_rad3 > (2 * PI)) lat_rad3 -= (2 * PI);
  while (lon_rad3 > (2 * PI)) lon_rad3 -= (2 * PI);
  while (lat_rad3 < 0) lat_rad3 += (2 * PI);
  while (lon_rad3 < 0) lon_rad3 += (2 * PI);
*/  
/*
  if (lat_rad3 == (double)0.00) lat_rad3 = 0.000000001; 
  if (lon_rad3 == (double)0.00) lon_rad3 = 0.000000001; 
*/
 
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
    
 /*   line(
    (longitude1 - midlon) * 111 * (float) Math.cos(radians(midlat)) / kmPerPixel, 
    (latitude1 - midlat) * 111 / kmPerPixel, 
    0, 
    0, 0, 0); /* x1, y1, z1, x2, y2, z2 */
  
 /*   line(
    (longitude2 - midlon) * 111 * (float) Math.cos(radians(midlat)) / kmPerPixel, 
    (latitude2 - midlat) * 111 / kmPerPixel, 
    0, 
    0, 0, 0); /* x1, y1, z1, x2, y2, z2 */
    
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
  }  
  else /* not close enough for a straight line to look OK */
  { 
    /* just call myself twice with half the distance */
    earthArcLevel++;
    earthArc(latitude1, longitude1, altitude1, midlat, midlon, midalt); 
    earthArc(midlat, midlon, midalt, latitude2, longitude2, altitude2); 
    earthArcLevel--;
  }  
}
 

void draw() {
 
  background(0);
 
  /*
  rotateX(PI/6);
  rotateY(PI/6);
  */ 

  /* lemley:  make a function of mouseX and mouseY, when mousePressed */
  /* this changes ths global viewpoint.  */ 

  
  if (mousePressed && 
    (mouseX > width * 0.25 && mouseX < width * 0.75) &&
    (mouseY > height * 0.25 && mouseY < height * 0.75)
  ) {
    /* as a visual aid, print a light box where the active mouse will move the viewpoint */
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
  
  
  translate(width/2, height/2, 0);  /* aha! This makes our drawing coordiate system zero-in-the-middle ! */
  rotateX(viewpointX); 
  rotateY(viewpointY);
  // rotateZ(23.4  *  0.01745329252); /* earth is tilted 23 degrees */
  drawGlobe();

  /* try to mark the poles */ 
  fill(20);  
  stroke(255,0,0); 
  //earthPoint(90.0, 0, 300); earthPoint(90.0, 0, 600); earthPoint(90.0, 0, 900);
  earthArc(90, 0, 0, 90, 0, 3000);
  stroke(0,0,255);
  //earthPoint(-90.0, 0, 300); earthPoint(-90.0, 0, 600); earthPoint(-90.0, 0, 900);
  earthArc(-90, 0, 0, -90, 0, 3000);
    
  /* mark the equator and +45 degrees north */ 
  stroke(0,180,0,120);

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
  
  /* mark a bunch more random points, to see how Processing.org handles the load 
 for (int i = 0; i <= 10000; i += 1) { 
      earthPoint(random(180.0) - 90, random(360.0) - 180, 600); 
  }
  */
  
  /* mark my house 
  stroke(255,255,255);
  earthPoint(35.0, -92.4321, 1000);
  earthPoint(45, -12, 1000); 
   */
  /* draw some difficult arcs from my house 
  earthArc(35.0, -92.4321, 1150, 45, -12, 0);
  earthArc(35.0, -92.4321, 1300, -30, -160, 0);
  earthArc(35.0, -92.4321, 1450, 22, 18, 0);
  earthArc(35.0, -92.4321, 1600, 66, -170, 0);
  earthArc(35.0, -92.4321, 1750, -90, 130, 0);
*/
 /* mark a bunch of random scribbles  */
 randomSeed(40);
 for (int i = 0; i <= 100; i += 1) { 
     stroke(random(255), random(255), random(255));
      earthArc(random(179.0) - 90, random(359.0) - 180, random(2500)+25 
              ,random(179.0) - 90, random(359.0) - 180, random(2500)+25); 
  }
  /* end lemley */

  
  /* begin example program  
  int index=0;

  for (int i = 0; i < num; i++) {
    pushMatrix();
 
    rotateX(pt[index++]);
    rotateY(pt[index++]);
 
    if(style[i*2+1]==0) {
      stroke(style[i*2]);
      noFill();
      strokeWeight(1);
      arcLine(0,0, pt[index++],pt[index++],pt[index++]);
    }
    else if(style[i*2+1]==1) {
      fill(style[i*2]);
      noStroke();
      arcLineBars(0,0, pt[index++],pt[index++],pt[index++]);
    }
    else {
      fill(style[i*2]);
      noStroke();
      arc(0,0, pt[index++],pt[index++],pt[index++]);
    }
 
    // increase rotation
    pt[index-5]+=pt[index]/10;
    pt[index-4]+=pt[index++]/20;
 
    popMatrix();
  }
  /* */
}
 
 
// Get blend of two colors
int colorBlended(float fract,
float r, float g, float b,
float r2, float g2, float b2, float a) {
 
  r2 = (r2 - r);
  g2 = (g2 - g);
  b2 = (b2 - b);
  return color(r + r2 * fract, g + g2 * fract, b + b2 * fract, a);
}
 

 
// Draw arc line
void arcLine(float x,float y,float deg,float rad,float w) {
  int a=(int)(min (deg/SINCOS_PRECISION,SINCOS_LENGTH-1));
  int numlines=(int)(w/2);
 
  for (int j=0; j<numlines; j++) {
    beginShape();
    for (int i=0; i<a; i++) { 
      vertex(cosLUT[i]*rad+x,sinLUT[i]*rad+y);
    }
    endShape();
    rad += 2;
  }
}
 
// Draw arc line with bars
void arcLineBars(float x,float y,float deg,float rad,float w) {
  int a = int((min (deg/SINCOS_PRECISION,SINCOS_LENGTH-1)));
  a /= 4;
 
  beginShape(QUADS);
  for (int i=0; i<a; i+=4) {
    vertex(cosLUT[i]*(rad)+x,sinLUT[i]*(rad)+y);
    vertex(cosLUT[i]*(rad+w)+x,sinLUT[i]*(rad+w)+y);
    vertex(cosLUT[i+2]*(rad+w)+x,sinLUT[i+2]*(rad+w)+y);
    vertex(cosLUT[i+2]*(rad)+x,sinLUT[i+2]*(rad)+y);
  }
  endShape();
}
 
// Draw solid arc
void arc(float x,float y,float deg,float rad,float w) {
  int a = int(min (deg/SINCOS_PRECISION,SINCOS_LENGTH-1));
  beginShape(QUAD_STRIP);
  for (int i = 0; i < a; i++) {
    vertex(cosLUT[i]*(rad)+x,sinLUT[i]*(rad)+y);
    vertex(cosLUT[i]*(rad+w)+x,sinLUT[i]*(rad+w)+y);
  }
  endShape();
}