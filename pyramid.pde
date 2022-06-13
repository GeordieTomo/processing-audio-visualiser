class Pyramid {
  // position tracking
  PVector position = new PVector();
  float initY;
  // check if it's off screen
  boolean offScreen = false;
  // rotation- only 1 dimension because the pyramids should face up
  float rotation;
  float scl;

  Pyramid(float x) {
    // set scale and position of pyramid
    position.x = x;
    scl = 400 - abs(x/5);
    position.z = zLevel;
    
    initY = yoff;
    // random rotation
    rotation = random(2*PI);
  }

  void update() {
    pushMatrix();
    // these are simply half of a super low poly sphere
    sphereDetail(1);
    
    // update the position based on the global plane motion
    position.y = -1700 - abs(position.x) + (yoff - initY) * scale;
    position.z = zLevel;
    
    translate(position.x,position.y,position.z);
    rotateX(PI/2);
    rotateY(rotation);
    
    // fade in when it enters from the background
    float op = min(255,map(position.y,-1700,-1200,0,255));
    stroke(255,op);
    fill(0,op);
    
    // make these increase in size based on the music amplitude to match the terrain
    sphere(scl + 100 *smoothAmp);
    
    popMatrix();
    
    // check if it's gone offscreen 
    if (position.y >= 1000) {
      offScreen = true;
    }
    
  }
}
