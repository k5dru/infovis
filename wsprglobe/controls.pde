HScrollbar hs1; 
HScrollbar spinRate;  
HScrollbar updateRate;  
HScrollbar coastBright;  
HScrollbar lightBright;  
HScrollbar observationWindow;  

boolButton coastlineButton; 
boolButton greylineButton;
boolButton spinButton;
boolButton updateButton;
boolButton sunPointButton;
boolButton showControlsButton;
boolButton showMarksButton;
boolButton showTextButton;

void setupControls() 
{ 

  /* float xposition, float yposition, int swidth, int sheight, int lethargy */
  hs1 = new HScrollbar(0, height-9, width, 16, 1);

  int buttonY = 100;
  int buttonX = 10;
  int yInc = 18;
  int buttonSize=10;

  showControlsButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  showControlsButton.setNominalValue("Show Controls");
  showControlsButton.setState(true);

  showMarksButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  showMarksButton.setNominalValue("Show Marks");
  showMarksButton.setState(false);

  showTextButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  showTextButton.setNominalValue("Show Text");
  showTextButton.setState(false);

  spinButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  spinButton.setNominalValue("Auto Spin");
  spinButton.setState(false);

  spinRate = new HScrollbar(buttonX, buttonY += (yInc * 2), width / 10, 16, 3);
  spinRate.setValue(0.6);
  
  coastlineButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  coastlineButton.setNominalValue("Show Coastlines");
  coastlineButton.setState(false);

  coastBright = new HScrollbar(buttonX, buttonY += (yInc * 2), width / 10, 16, 3);
  coastBright.setValue(0.7);

  greylineButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  greylineButton.setNominalValue("Show Greyline");
  greylineButton.setState(false);

  sunPointButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  sunPointButton.setNominalValue("Sun Point Source");
  sunPointButton.setState(false);

  lightBright = new HScrollbar(buttonX, buttonY += (yInc * 2), width / 10, 16, 3);
  lightBright.setValue(0.7);

  updateButton = new boolButton(buttonX, buttonY += yInc, buttonSize, buttonSize);
  updateButton.setNominalValue("Auto Update");
  updateButton.setState(false);

  updateRate = new HScrollbar(buttonX, buttonY += (yInc * 2), width / 10, 16, 3);

  observationWindow = new HScrollbar(buttonX, buttonY += (yInc * 2), width / 10, 16, 3);

}  

void updateControls() 
{ 
  /* update controls that need updating */

  strokeWeight(2);
  showControlsButton.update(); 
  showControlsButton.display();

  if (showControlsButton.getState()) { 
    hs1.update();
    hs1.setNominalValue(dateFormat.format(endDate));
    hs1.display();

    spinRate.update();
    spinRate.setNominalValue("Spin Rate: " + round(spinRate.getValue() * 100) + "%" );
    spinRate.display();

    showMarksButton.update(); 
    showMarksButton.display();

    showTextButton.update(); 
    showTextButton.display();

    coastlineButton.update(); 
    coastlineButton.display();
    
    coastBright.update();
    coastBright.setNominalValue("Coast Brightness: " + round(coastBright.getValue() * 100) + "%" );
    coastBright.display();


    greylineButton.update(); 
    greylineButton.display();

    lightBright.update();
    lightBright.setNominalValue("Light Brightness: " + round(lightBright.getValue() * 100) + "%" );
    lightBright.display();

    
    spinButton.update(); 
    spinButton.display();

    updateButton.update(); 
    updateButton.display();
    
    updateRate.update();
    updateRate.setNominalValue("Update Rate: " + round(updateRate.getValue() * 100) + "%" );
    updateRate.display();

    observationWindow.update();
    observationWindow.setNominalValue("Observation Window: " + round(observationWindow.getValue() * 10000) / 100.0 + "%" );
    observationWindow.display();
    
    sunPointButton.update(); 
    sunPointButton.display();
  }
}


/* HScrollbar lifted entirely from the Scrollbar example in Processing 3.3.6, 
 modified to display a nominal value over the slider and externally set the position 
 */

/* DONE:  add a setpos method. */

/**
 * Scrollbar. 
 * 
 * Move the scrollbars left and right to change the positions of the images. 
 */

class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;
  String nominalvalue = "";    /* james: what, if anything, to display over the slider? */ 
 // float value;                /* james:  make this go from 0.0 to 1.0 based on spos */ 

  /* float xposition, float yposition, int swidth, int sheight, int lethargy */
  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 0) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
      mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void setNominalValue(String s) { 
    nominalvalue = s;
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);

    if (nominalvalue.length() > 0) { 
      float tw = textWidth(nominalvalue);
      float textHeight = 8;  /* how to make dynamic? */
      float textxpos = round(min(width - tw, max(0, spos - (tw / 2))));
      textAlign(LEFT);
      fill (255, 192, 0);  /* like old amber screens */

      text(nominalvalue, textxpos, ypos - textHeight);
    }
  }

  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }

  float getValue() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return (spos - sposMin) / (sposMax - sposMin);
  }

  void setValue(float f) {
    newspos = sposMin + (sposMax - sposMin) * min(1.0, max(f,0.0));
  }
}


/*  original sample code:   
 
 
 HScrollbar hs1, hs2;  // Two scrollbars
 PImage img1, img2;  // Two images to load
 
 void setup() {
 size(640, 360);
 noStroke();
 
 hs1 = new HScrollbar(0, height/2-8, width, 16, 16);
 hs2 = new HScrollbar(0, height/2+8, width, 16, 16);
 
 // Load images
 img1 = loadImage("seedTop.jpg");
 img2 = loadImage("seedBottom.jpg");
 }
 
 void draw() {
 background(255);
 
 // Get the position of the img1 scrollbar
 // and convert to a value to display the img1 image 
 float img1Pos = hs1.getPos()-width/2;
 fill(255);
 image(img1, width/2-img1.width/2 + img1Pos*1.5, 0);
 
 // Get the position of the img2 scrollbar
 // and convert to a value to display the img2 image
 float img2Pos = hs2.getPos()-width/2;
 fill(255);
 image(img2, width/2-img2.width/2 + img2Pos*1.5, height/2);
 
 hs1.update();
 hs2.update();
 hs1.display();
 hs2.display();
 
 stroke(0);
 line(0, height/2, width, height/2);
 }
 
 */


class boolButton {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  boolean over;           // is the mouse over the slider?
  boolean ready = true;  // ready to be clicked.  Suppress clicks if one has just happened and mouse is still clicked. */
  boolean currentState = false;
  String nominalvalue = "";    // what, if anything, to display over the slider? 
  boolean prevPressed = false;

  /* float xposition, float yposition, int swidth, int sheight, int lethargy */
  boolButton (float xp, float yp, int sw, int sh) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    xpos = xp;
    ypos = yp-sheight/2;
  }

  void update() {
    if (overEvent()) {
      over = true;
      if (mousePressed == false) 
        ready = true;
    } else {
      over = false;
      ready = true;
    }

    if (mousePressed && over && ready) {
      ready = false;
      currentState = !currentState;
    }
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
      mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void setNominalValue(String s) { 
    nominalvalue = s;
  }

  void display() {
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over) {
      if (currentState) 
      {
        stroke(0, 180, 0);
        fill(0, 151, 0);
      } else
      {
        fill(64);
        stroke(128, 0, 0);
      }
    } else {
      if (currentState) 
      {
        stroke(0, 148, 0);
        fill(0, 132, 0);
      } else
      {
        stroke(96, 0, 0);
        fill(32);
      }
    }

    rect(xpos, ypos, swidth, sheight);

    if (currentState)  /* make a checkmark for the colorblind :) */
    { 
      stroke(222, 222, 0); 
      line(xpos, ypos, xpos + (swidth / 2), ypos + (sheight / 2));
      line(xpos + (swidth / 2), ypos + (sheight / 2), xpos + swidth * 2, ypos - sheight / 2);
    }

    if (nominalvalue.length() > 0) { 
      //      float tw = textWidth(nominalvalue);
      //      float textHeight = 8;  /* how to make dynamic? */
      //      float textxpos = min(width - tw, max(0, xpos - (tw / 2)));
      textAlign(LEFT);
      noStroke();
      fill (255, 192, 0);  /* like old amber screens */

      text(nominalvalue, xpos + swidth + 4, ypos + sheight);
    }
  }

  boolean getState() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return currentState;
  }

  void setState(boolean b) {
    currentState = b;
  }
}