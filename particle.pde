class Particle {
  // position variables
  float x, y, z;
  // track speed and previous position
  float pz,speed;
  // time of start
  float tStart;
  // check if it's on the screen
  boolean offScreen = false;
  // boolean to control if it's a star or an asteroid
  boolean isAsteroid = false;
  // current rotation of object
  PVector rotation;


  Particle(float w, boolean ast) {
    // setup x position based on the input band frequency
    x = (map(w, 0,60, 10, width/2) * (int(random(0,2))-0.5)*2);//random((w-32)/64 * width - 20, (w-32)/64*width+20);
    y = random(-height/2, height/2);
    pz = z = -width;
    // set some specific asteroid values, so make it slower if it's an asteroid than a star
    if (ast)
      speed = random(15,25);
    else
      speed = random(30,100);
    isAsteroid = ast;
    tStart = millis();
    // random rotation for asteroids (doesn't affect stars)
    rotation = PVector.random3D();
  }

  void update() {
    // move forward on the screen
    z = z + speed +flySpeed;
    // check if it's out of view
    if (z > width) {
      offScreen = true;
    }
    
    // if it's an asteroid
    if (isAsteroid) {
      // draw a rotated low poly sphere
      float opacity = (millis() - tStart)/10;
      opacity = min(255,opacity);
      stroke(sphereCol,opacity);
      noFill();
      sphereDetail(3);
      pushMatrix();
      translate(x,z,y);
      rotateX(rotation.x);
      rotateY(rotation.y);
      rotateZ(rotation.z);
      rotation.add(new PVector(0.01,0.02,0.05));
      sphere((smoothAmp*10+15)*opacity/255);
      popMatrix();
    } else {
      // otherwise, simply draw a line between the previous position of the star and the current position
      stroke(sphereCol,80);
      strokeWeight(map(z, -width, width, 0, 6+6*smoothAmp));
      //point(x, z, y);
      line(x,z,y, x,pz,y);
      strokeWeight(2);
    }
    // set prev pos to current pos at end of each update
    pz = z;
    
  }
}
