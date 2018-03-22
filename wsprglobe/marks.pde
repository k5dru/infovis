
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
  int observation_age; 
  int alpha;
  float freq;
  int cr, cg, cb;

  Mark(float a, float b, float c, float d, float e, float f, int g, int h, int i, float j) { 
    lat1=a;
    lon1=b;
    alt1=c;
    lat2=d;
    lon2=e;
    alt2=f;
    quality_quartile = g;
    drift = h;
    observation_age = i;
    freq = j;
   // todo: intellegently decrease mark brightness given observation window and mark age. 
    alpha=(255 - observation_age * 16);
    if (alpha < 0) {  
      alpha = 0; 
    }
 

}
  
  void display() { 

    noFill();
    strokeWeight(5 * markWeight.getValue()); 


    /* colors: 
    if (freq < 4) { cr = 255; cg = 0; cb = 0; }         // red
    else if (freq < 11) { cr = 255; cg = 51; cb = 0; }  // orange  
    else if (freq < 15) { cr = 255; cg = 255; cb = 0; } // yellow 
    else if (freq < 25) { cr = 0; cg = 255; cb = 0; }  // green  
    else if (freq < 35) { cr = 0; cg = 0; cb = 255;}   // blue  
    else  { cr = 255; cg = 0; cb = 255;}               // fuchsia  
    */   
    
    if ( colorFreqButton.getState() ) { 
      /* set color based on frequency */ 
      if (freq < 4) { cr = 255; cg = 255; cb = 0; }        // yellow 
      else if (freq > 10 ) { cr = 0; cg = 255; cb = 255;}  // bluegreen  
      else  { cr = 255; cg = 255; cb = 255;}               // white
      stroke(cr,cg,cb, alpha * markBright.getValue());    
    } 
    else if ( colorDriftButton.getState() ) { 
     /* set color based on drift: */
      if (drift > 0) { cr = 255; cg = 255; cb = 0; }        // yellow 
      else if (drift < 0) { cr = 0; cg = 255; cb = 255;}  // bluegreen  
      else  { cr = 255; cg = 255; cb = 255;}               // white
      stroke(cr,cg,cb, alpha * markBright.getValue());    
    }
    else { 
      stroke(255,255,255, alpha * markBright.getValue());          
    }
     
    if (showMarksButton.getState()) {
      earthArc(lat1, lon1, txAltitudeButton.getState() ? 1000 : 10, lat2, lon2, 10);  /* 10km high to make sure the marks aren't obscured by other globe marks */
    }

    if (txGlyphButton.getState()) { 
       /* draw a rough triangle around the transmit site */
      earthGlyph(lat1, lon1, txAltitudeButton.getState() ? 1000 : 10, 3);
       /* and a circle around the receive site */
      earthGlyph(lat2, lon2,  10, 1);
    }
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
+" , rx_longitude, distance_km, quality_quartile, drift, frequency  "
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
        pgsql.getInt("observation_age"),
        pgsql.getInt("frequency") 
      )
    );
  }
    
  println (newMarks.size() + " marks loaded in " + (millis() - startMillis) + " ms"); 
  marks=newMarks; 
  loadingMarks = false;
  
}