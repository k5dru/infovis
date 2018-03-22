
void drawGlyph(int glyphType)
{
  if (glyphType == 1) {  /* circle */
   ellipseMode(CENTER);
    noFill();
    float roughSize = 130 / kmPerPixel; // was 100
    ellipse(0, 0, roughSize, roughSize);
  }  
  else if (glyphType == 2) {  /*  an X, fast but kind of ugly */
    float roughSize = 40 / kmPerPixel;
    line(-roughSize,-roughSize,0,roughSize,roughSize,0);
    line(roughSize,-roughSize,0,-roughSize,roughSize,0);
  }  
  else if (glyphType == 3) {  /*  a rough triangle - sorry for lack of precise math */
     float roughSize = 70 / kmPerPixel;
     line( 0, -roughSize,      0,   -roughSize*0.9, roughSize*0.5,    0);
     line( -roughSize*0.9, roughSize*0.5,      0,   +roughSize*0.9, roughSize*0.5,    0);
     line( +roughSize*0.9, roughSize*0.5,      0,    0, -roughSize,    0);
  } 
  else if (glyphType == 4) {  /* a sun position indicator, two concentric circles */
    ellipseMode(CENTER);
    noFill();
    float roughSize = 250 / kmPerPixel; 
    ellipse(0, 0, roughSize, roughSize);
    roughSize = 150 / kmPerPixel; 
    ellipse(0, 0, roughSize, roughSize);
  }
  else if (glyphType == 5) {  /* an anti-sun position indicator, crossed out */
    ellipseMode(CENTER);
    noFill();
    float roughSize = 250 / kmPerPixel; 
    ellipse(0, 0, roughSize, roughSize);
    roughSize = 150 / kmPerPixel; 
    ellipse(0, 0, roughSize, roughSize);
    roughSize *= 0.62;
    line(-roughSize,-roughSize,0,roughSize,roughSize,0);
    line(roughSize,-roughSize,0,-roughSize,roughSize,0);
  }
}

void earthGlyph(float latitude, float longitude, float altitude, int glyphType)
{ 
  /* challenge:  Draw a shape at a particular latitude, longitude, and altitude in km. */
  pushMatrix(); 
  rotateY( radians(longitude) ); /* must do Y axis first  */
  rotateX( radians(latitude) );
  translate(0, 0, ((earthRadius + altitude)/ kmPerPixel)); /* translate Z axis */

  drawGlyph(glyphType); 

  popMatrix();
}


int earthArcLevel = 0; /* recursive level tracking variable to prevent stack overflow because I am not a math major */

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

/*   This works very very well: */ 
    line(
      (longitude1 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude1) * km_per_degree_latitude / kmPerPixel, 
      (altitude1 - midalt) / kmPerPixel, 
      (longitude2 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude2) * km_per_degree_latitude / kmPerPixel, 
      (altitude2 - midalt) / kmPerPixel // change this to just midalt for a cool effect 
    );


  
  /*  -- shaded dashed lines and indicate direction.  
    beginShape(LINES);
    stroke(0);
    vertex(
          (longitude1 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude1) * km_per_degree_latitude / kmPerPixel, 
      (altitude1 - midalt) / kmPerPixel) ; 
    stroke(200, 150);
    vertex(
      (longitude2 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude2) * km_per_degree_latitude / kmPerPixel, 
      (altitude2 - midalt) / kmPerPixel  );
    endShape();
*/

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

/*
   Exactly like earthArc, but revert to cartesian coordinates and skip the fancy math. 
   This is only useful for short distances (like coastlines) or cartesian lines like latitudes and meridians.
*/
void fastArc(float latitude1, float longitude1, float altitude1, float latitude2, float longitude2, float altitude2)
{
  /* same as earthArc, but using cartesian midpoint and distance. */
  /* is there a midpoint between there and here? */
  float midlat = (latitude1 + 90) + ((latitude2 + 90) - (latitude1 + 90)) / 2.0 - 90; 
  float midlon = (longitude1 + 180) + ((longitude2 + 180) - (longitude1 + 180)) / 2.0 - 180;
  float midalt = (altitude2 + altitude1) / 2.0;

  if (  (
    abs(latitude2 - latitude1) < 3 
    && 
    (  
    abs(longitude2 - longitude1) < 3
    || abs((longitude2 + 360) - longitude1) < 3  /* this is not working :( */
    || abs(longitude2 - (longitude1 + 360)) < 3
    )
    ) )
  {
    /* don't draw a line across the international date line, because it's just not working. :( */
    if (longitude2 > 170 && longitude1 < -170) return;
    if (longitude1 > 170 && longitude2 < -170) return;

    /* if the points are close in space, just draw a line, because the Earth is flat a short-range. */
    pushMatrix(); 
    rotateY( radians (midlon) ); /* must do Y axis first, longitude  */

    rotateX( radians (midlat) );    /* latitude */
    translate(0, 0, ((earthRadius + midalt)/ kmPerPixel)); /* translate Z axis */

    float km_per_degree_latitude = 111.0 * ((earthRadius + midalt) / earthRadius);
    float km_per_degree_longitude = 111.0 * ((earthRadius + midalt) / earthRadius) * (float) Math.cos(radians(midlat));

   /*   stroke(random(255));  */

/*   This works very very well: */ 
    line(
      (longitude1 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude1) * km_per_degree_latitude / kmPerPixel, 
      (altitude1 - midalt) / kmPerPixel, 
      (longitude2 - midlon) * km_per_degree_longitude / kmPerPixel, 
      (midlat - latitude2) * km_per_degree_latitude / kmPerPixel, 
      (altitude2 - midalt) / kmPerPixel // change this to just midalt for a cool effect 
    );

    popMatrix();
  } else /* not close enough for a straight line to look OK */
  { 
    /* just call myself twice with half the distance */
    fastArc(latitude1, longitude1, altitude1, midlat, midlon, midalt); 
    fastArc(midlat, midlon, midalt, latitude2, longitude2, altitude2);
  }
}