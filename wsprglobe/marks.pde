/* database connection: */

import de.bezier.data.sql.*;    
PostgreSQL pgsql;

void setupDatabase()
{ 
  /* thanks to  fjenett 20081129 */
  /* make database connection */
  String user     = "lemley";
  String pass     = "InfoVisIsAwesome";
  String database = "lemley";
  String dbhost = "localhost";
  // if using Docker defaults (see 000_optional_docker_postgresql.sh for postgresql install command line)
  //database="postgres"; 
  //user="postgres";

  // if on windows PC with postgresql in vm:
//  { 
//    user     = "";
//    pass     = "";
//    database = "";
//    dbhost = "192.168.56.103";
//  }
  
    
  //
  pgsql = new PostgreSQL( this, dbhost, database, user, pass );

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
      //println( pgsql.getString("tx_grid") );          //| character varying(6)     | 
      println( pgsql.getString("rx_call") );          //| character varying(12)    | 
      //println( pgsql.getString("rx_grid") );          //| character varying(6)     | 
      // println( pgsql.getInt("distance_km") );      //| smallint                 | 
      // println( pgsql.getInt("azimuth") );          //| smallint                 | 
      println( pgsql.getInt("tx_dbm") );           //| smallint                 | 
      println( pgsql.getInt("rx_snr") );           //| smallint                 | 
      println( pgsql.getFloat("frequency") );        //| real                     | 
      println( pgsql.getInt("drift") );            //| smallint                 | 
      //println( pgsql.getFloat("quality") );          //| real                     | 
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
  } 
  catch (ParseException e) {
    e.printStackTrace();
  }
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
  int observation_age; 
  int alpha;
  float freq;
  int cr, cg, cb;
  String tx_call; 
  String rx_call;

  Mark(float a, float b, float c, float d, float e, float f, int g, int h, int i, float j, String tc, String rc) { 
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
 
    tx_call = tc;
    rx_call = rc;
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
      if (drift < 0) { cr = 255; cg = 255; cb = 0; }        // yellow 
      else if (drift > 0) { cr = 0; cg = 255; cb = 255;}  // bluegreen  
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
      earthGlyph(lat1, lon1, txAltitudeButton.getState() ? 1000 : 10, 3, tx_call);
       /* and a circle around the receive site */
      earthGlyph(lat2, lon2,  10, 1, rx_call);
    }
  }
}

ArrayList<Mark> marks;         // the list that will be displayed from always
ArrayList<Mark> newMarks;      // work list, to load then swap to the marks list
boolean loadingMarks = false;  // semaphore for loading the newMarks arraylist 

//void loadMarks(Date beginDate, Date endDate) {
 
void loadMarks() {

  SimpleDateFormat dateUTC = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss Z");
  dateUTC.setTimeZone(TimeZone.getTimeZone("UTC"));
  
  if (loadingMarks) return;  // some other thread beat me to it. 
  loadingMarks = true;       // set the semaphore. TODO: use a proper semaphore method. 
  
  int startMillis = millis(); 

//  print("### entering loadMarks("+ dateUTC.format(beginDate) + ","+ dateUTC.format(endDate) +") ... "); 
  newMarks = new ArrayList<Mark>();  /* what happens to the old one?  It's Java - presumably it gets "collected".  */

  String SQL=" select tx_call "
+", tx_latitude"
+",  tx_longitude"
+", rx_call"
+", rx_latitude"
+" , rx_longitude"
+" , quality_quartile, drift, frequency"
+" , extract(MINUTES from ('" + dateFormat.format(endDate) + "'::timestamp with time zone - observationtime)) as observation_age"
+" , tx_call, rx_call "
+"  from wspr       "
+"  where observationtime between '" + dateUTC.format(beginDate) + "'::timestamp with time zone"
+"                            and '" + dateUTC.format(endDate) + "'::timestamp with time zone"
+" and quality_quartile = 4" 
//+" and rx_snr < -22 "  /* mode is -22, mean is -14.5 */
// on new Windows load, these ended up as positive integers.  Why? 
// they are negative on the stage table.  How did that affect my quality calculation?
;

  pgsql.query(SQL);
     
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
        pgsql.getInt("frequency"),
        pgsql.getString("tx_call"),
        pgsql.getString("rx_call")
      )
    );
  }
    
//  println (newMarks.size() + " marks loaded in " + (millis() - startMillis) + " ms");
//  println ("Query is: " + SQL); 
  //marks=newMarks; 
  loadingMarks = false;
}