import processing.sound.*;

// cols and rows for the triangle grid
float columns,rows;

// width and height of the triangle grid
float w = 4300;
float h = 2500;

// scale of the triangle grid
float scale = 40;

// track current 'depth' of the grid
float depth = 0;
// how smooth to make the high points and low points of the grid
float smoothness = 10;
// variable to modify the perlin noise field in a third direction
float z = 0;
// position of the grid
float yoff = 0;
// extra offset for the grid
float yOffset = 0;
// z level of the grid (up and down position)
float zLevel = 500;

// camera rotation
float rotation = 0;
// state machine current state (which point of the playback is it up to)
int stateMachine = -1;

// transition and smoothed variables to fade between different states
float transition = 0;
float transition2 = 0;
float smooth = 0;
float smooth2 = 0;

// speed to move forward along the grid
float flySpeed = 0;

// audio analysis
SoundFile audio;
Amplitude amp;
// current amplitude of audio (with smoothing)
float smoothAmp;

// variables to track time used in state machine
float timePassed = 0;
float timeOfStart = 0;
// extra timer to fade colours
float colorTimeStart = 0;

// arraylist to contain particles and pyramids
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Pyramid> pyramids = new ArrayList<Pyramid>();

// fast fourier transform (audio broken into frequency) and smoothing variable
FFT fft;
int bands = 128;
float smoothingAmount = 0.2;

// output of fast fourier transform
float[] sum = new float[bands];

// modify position/height of asteroids and colour
float asteroidH;
float sphereCol;


void setup() {
  // setup fullscreen 3D canvas
  fullScreen(P3D);
  // testing 1080p on screen on desktop computer
  //size(1920,1080,P3D);
  // disable cursor
  noCursor();
  
  // setup triangle grid
  columns = w / scale;
  rows = h / scale;
    
  // play audio - just an instrumental track I made myself which had some good drumbeats to visualise
  audio = new SoundFile(this, "soundtrack.wav");
  audio.play();
  
  // route audio into analysis
  amp = new Amplitude(this);
  amp.input(audio);
  
  fft = new FFT(this, bands);
  fft.input(audio);
  
  // set start time of program (once audio has been loaded)
  timeOfStart = millis();
}

void draw() {
  
  // -----------------------------------------------------------------------------------------------------------
  // this section mainly is setting up basic canvas
  // background and other global variables
  // -----------------------------------------------------------------------------------------------------------
  
  
  // set background to black and default no stroke or fill
  background(0);
  noStroke();
  noFill();
  
  // update time passed tracker
  timePassed = millis() - timeOfStart;
  
  // update the audio analysis (amplitude and fft)
  smoothAmp += (amp.analyze()*2-smoothAmp)*smoothingAmount;
  fft.analyze();
  
  
  // -----------------------------------------------------------------------------------------------------------
  // state specific events - based on "stateMachine" variable set some values of the visualiser
  // this section is mostly the camera movement, timings of states and smooth transition values which are used elsewhere
  // -----------------------------------------------------------------------------------------------------------

  switch (stateMachine) {
    case -1:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed)/10000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // slowly move camera backwards
      yOffset = lerp(0,500,smooth);
      // move camera up
      zLevel = lerp(500,0,smooth);
      // if past 10 seconds, go to the next state
      if (timePassed >= 10000 && timePassed < 20000){
        // reset transition state from 1 to 0
        transition = 0;
        stateMachine=0;
      }
      break;
    case 0:
      // calculate how far time has passed in the current state
      transition = min(1,((timePassed - 10000))/5000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // speed up camera to a rate of 1
      flySpeed = lerp(0,0.2,smooth);
      
      // if past 15 seconds
      if (timePassed >= 15000) {
        // reset transition state from 1 to 0
        transition = 0;
        // go to the next state
        stateMachine++;
      }
      break;
    case 1:    
      // calculate how far time has passed in the current state
      transition = min(1,((timePassed - 15000))/7000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // rotate the camera to look down onto the grid
      rotation = lerp(0,PI/4,smooth);
      // start the terrain being "3D" smooth to a depth of 300
      depth = lerp(0,300,smooth);
      // set fly speed
      flySpeed = 0.2;
      // set y (forwards and backwards along the plane) offset
      yOffset = 500;
      
      // if past 22 seconds
      if (timePassed >= 22000) {
        // reset transition variable
        transition = 0;
        // move to next state
        stateMachine++;
      }
      break;
    case 2:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed - 22000)/11000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // slow down flyspeed
      flySpeed = lerp(0.2,0.1,smooth);
      // once 33 seconds have passed
      if (timePassed >= 33000) {
        // move to next state
        transition = 0;
        stateMachine++;
      }
      break;
    case 3:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed - 33000)/3000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // set fly speed based on the amplitude of the audio
      flySpeed = lerp(0.4,0.2,smoothAmp);
      // once past 36 seconds
      if (timePassed >= 36000) {
        // go to next state
        transition = 0;
        stateMachine++;
      }
      break;
    case 4:
      // once past 46 seconds
      if (timePassed >= 46000) {
        // go to next state
        stateMachine++;
      }
      break;
    case 5:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed-46000)/15000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // set camera angle to 90 degrees - looking directly fowards
      rotation = lerp(PI/4,PI/2,smooth);
      // move the terrain down further so the camera doesn't enter the terrain
      zLevel = lerp(0,-500,smooth);
      // speed up camera even more
      flySpeed = lerp(0.4,1,smooth);
      // if past 61 seconds
      if (timePassed >= 61000) {
        // go to the next state
        stateMachine++;
      }
      
      break;
    case 6:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed-61000)/10000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // set fly speed to 0 and turn the camera back to facing downwards onto the plane
      // centre the y offset back to 0
      yOffset = lerp(500,0,smooth);
      rotation = lerp(PI/2,0,smooth);
      flySpeed = lerp(1,0,smooth);
      
      // once past 71 seconds
      if (timePassed >= 71000) {
        // reset the colour timer
        colorTimeStart = timePassed;
        // reset transition variables
        transition = smooth = 0;
        // go to the next state
        stateMachine++; 
      }
      
      break;
    case 7:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed-71000)/5000);    
      // calculate how far time has passed in the current state
      transition2 = min(1,(timePassed-71000)/20000);
      // return a smoothed version of the time passed in the current state
      smooth = smoothstep(0,1,transition);
      // return a smoothed version of the time passed in the current state
      smooth2 = smoothstep(0,1,transition2);
      // set fly speed to 0 and facing down camera
      yOffset = 0;
      rotation = 0;
      flySpeed = 0;
      
      // if it's the second time through
      if (timeOfStart >= 45000) {
        zLevel = lerp(0,500,smooth2); 
        // slowly increase the z level (camera closeness to plane)
      }
      
      // if it reaches 91 seconds
      if (timePassed >= 91000 && timeOfStart <= 45000) {
         // if it's the first time through this state
         timeOfStart += 45000;
         // go back to state 5
         stateMachine = 5;
      } else if (timePassed >= 91000) {
         // otherwise, go to the next state
         stateMachine++; 
      }
    break;
    case 8:    
      // calculate how far time has passed in the current state
      transition = min(1,(timePassed-91000)/1000);
      // return a smoothed version of the time passed in the current state
      float audioRate = smoothstep(1,0,transition);
      // slow down the audio to 0
      audio.rate(max(0.0001,audioRate));
      if (audioRate <= 0) {
        // end program
        exit();
      }
      break;
    default: 
      break;
  }
  
  // move the terrain backwards based on the flyspeed
  yoff += flySpeed;
  
  // -----------------------------------------------------------------------------------------------------------
  // This section is in charge of generating the "terrain" or triangle grid
  // inside the for loops it calculates the colour of the terrain and so on
  // -----------------------------------------------------------------------------------------------------------
  
  pushMatrix();
  // set the camera position and rotation (really rotating the object)
  translate(width/2,height/2);
  rotateX(rotation);
  
  // if it's in state 7 add some extra rotation in the Z axis
  if (stateMachine == 7 && timeOfStart >= 45000)
    rotateZ(2*PI*smooth2);
  
  // set the position for the grid to be generated
  translate(-w/2,-h/2-yOffset,zLevel);
  
  // for loop iterates through grid to create triangle strip mesh
  for (float y = 0; y < rows - 1; y++) {
    // create each individual row of triagles as a seperate shape
    beginShape(TRIANGLE_STRIP);
    for (float x = 0; x < columns; x++) {
      
      // creates the two vertices required for each triangle
      for (int i = 0; i < 2; i++){
              
        // calculate the height of the current vertex
        float h = depth*(0.5+smoothAmp)*noise((x+i)/smoothness, ((y+i)+yoff%1-yoff)/smoothness,z);
        
        // calculate the colour based on the current state
        switch (stateMachine) {
          case -1:
            // rainbow (colorTest function)
            color c = (colorTest(x+i,y+i,255));
            //stroke(lerpColor(lerpColor(c,color(255),smooth),color(0),(1-((y+i)/rows))));
            noStroke();
            fill(c);
            break;
          case 0:
            // fade rainbow to black
            noStroke();
            fill(colorTest(x+i,y+i,255*(1-smooth)));
            break;
          case 1:
            // fade the stroke to a blue green terrain (blue at lowest, green at highest)
            color s = color((1-smooth)*255,(1-smooth)*255 + h/depth * 255,(1-smooth)*255 + (1-h/depth)*255,255*smooth);
            color sf = lerpColor(s,color(0,0),(1-((y+i)/rows)));
            stroke(sf);
            fill(0,smooth);
            break;
          case 2:
            // fill the triangles to the same colour
            color str = color(0, h/depth * 255,(1-h/depth)*255,255);
            color strf = lerpColor(str,color(0),(1-((y+i)/rows)));
            color s1f = lerpColor(strf,color(0),1-smooth);
            stroke(strf);
            fill(s1f);
            break;
          case 3:
            // rounding effect on blue and green, gives some expression
            noStroke();
            fill(0,round(h/depth) * 255,round(1-h/depth)*255,255);
            break;
          case 4:
            // fade into blue green terrain to white grid, based on the amplitude of the audio            
            color s2 = color((1-smooth)*255,(1-smooth)*255 + h/depth * 255,(1-smooth)*255 + (1-h/depth)*255,255);
            color s2f = lerpColor(s2,color(0),(1-((y+i)/rows)));
            
            // if the amplitude drops below 0.5
            if (smoothAmp < 0.5) {
              // set the fade between white grid and blue green terrain
              stroke(lerpColor(color(255, (0.5-smoothAmp) * 2 * 255),color(0),(1-((y+i)/rows))));
              fill(lerpColor(s2f,color(0),1-(smoothAmp*2)));
            }
            else {
              // just set the blue green terrain
              noStroke();            
              fill(s2f);
            }
            break;
          // for both states
          case 5:
          case 6:
            // set the triangles to blue and green terrain fading to white grid when volume is low
            color s3 = color(0, h/depth * 255,(1-h/depth)*255,255);
            color s3f = lerpColor(s3,color(0),(1-((y+i)/rows)));
            
            // if the amplitude drops below 0.5
            if (smoothAmp < 0.5) {
              // set the fade between white grid and blue green terrain
              stroke(lerpColor(color(255, (0.5-smoothAmp) * 2 * 255),color(0),(1-((y+i)/rows))));
              fill(lerpColor(s3f,color(0),1-(smoothAmp*2)));
            }
            else {
              // just set the blue green terrain
              noStroke();            
              fill(s3f);
            }
            break;
          case 7:
          case 8:
            // fade back to rainbow from terrain blue green
            color s4 = color(0, h/depth * 255,(1-h/depth)*255,255);
            color s4f = lerpColor(s4,color(0),(1-((y+i)/rows)));
            
            color c3 = (colorTest(x+i,y+i,255));
         
            fill(lerpColor(s4f,c3,smooth));
            break;
          default:
            stroke(255);
        }
        // create the vertex
        vertex((x+i)*scale, ((y+i)+yoff%1)*scale, h);
      }
      
    }
    // end the shape at the end of one row of triangles
    endShape();
  }
  // increment the perlin noise field
  z += 0.0025;
  
  
  // -----------------------------------------------------------------------------------------------------------
  // This section creates the focal point or "spheres"
  // which are in the foreground of the animation
  // -----------------------------------------------------------------------------------------------------------
  
  // height of terrain in middle
  float hnew = depth*(0.5+smoothAmp)*noise((columns/2)/smoothness, ((columns/2)+yoff%1-yoff)/smoothness,z) +zLevel + 200;
  asteroidH += (hnew-asteroidH)*.1;
  
  popMatrix();
  
  // reset transform matrix
  
  pushMatrix();
  
  // set the colour of the sphere based on the amplitude of music (from white to black)
  sphereCol = max(0, min(255,map(smoothAmp, 0.4, 1, 255,0)));
  
  fill(sphereCol); 
  // set a white stroke for high amplitudes
  if (smoothAmp < 0.8)
    noStroke();
  else
    stroke(255);
    
  // main centre sphere
  // change the number of verteces based on the amplitude - less when smaller and more when bigger
  sphereDetail(int(2 + smoothAmp*10));
  // set translation and rotation
  translate(width/2,height/2,0);
  rotateX(rotation);
  // add an extra offset to keep the sphere centred roughly, asteroidH makes it follow the height of the terrain
  if (rotation <= PI/4)
    translate(0,rotation/PI * 1000,asteroidH);
  else
    translate(0,(0.5 - rotation/PI) * 1000,asteroidH);
  
  // rotate the spheres
  rotateX(z*2);
  rotateY(z*6);
  rotateZ(z*10);
  // sphere size based on amplitude
  sphere(30 + 150*smoothAmp);
  
  // inverse rotation
  rotateZ(-z*10);
  rotateY(-z*6);
  rotateX(-z*2);
  // slower rotation for outer sphere
  rotateZ(z);
  rotateY(z);
  rotateX(z);
  // low detail sphere
  sphereDetail(2);
  // transparent wireframe
  stroke(255);
  noFill();
  // set size by amplitude, but more constant than inner sphere
  sphere(200+smoothAmp*50);
  
  popMatrix();
  
  translate(width/2,height/2);
  rotateX(rotation);
  
  if (stateMachine == 7 && timeOfStart >= 45000) // rotate whole view if in state 7
    rotateZ(2*PI*smooth2);
  
  
    
  // -----------------------------------------------------------------------------------------------------------
  // These final few for loops are in charge of managing instanced objects, which are asteroids, particles and
  // pyramids
  // -----------------------------------------------------------------------------------------------------------
  
  
  // add pyramids at set intervals of time, up to 4 total instanced
  
  if (pyramids.size() < 4 && (timePassed % 4500 <= 15)) {
    if (pyramids.size()%2 == 1)
      pyramids.add(new Pyramid((int(random(0,2))-0.5) * 2 * random(500,700))); 
    else
      pyramids.add(new Pyramid((int(random(0,2))-0.5) * 2 * random(900,1200))); 
  }
  
  // update each pyramid which has been created
  for (int i = 0; i < pyramids.size(); i++) {
     pyramids.get(i).update(); 
  }
  
  // remove the pyramids once they are off screen
  for (int i = 0; i < pyramids.size(); i++) {
    if (pyramids.get(i).offScreen) {
      pyramids.remove(i);
      i--;
    }
  }
  
  
  // for each band of audio, if the amplitude is greater than 0.01 generate a new particle
  // lower frequencies are instanced in the centre of the screen, while higher frequencies are to the outside
  for (int i = 0; i < bands; i++) {
    // Smooth the FFT spectrum data by smoothing factor
    sum[i] += (fft.spectrum[i] - sum[i]) * smoothingAmount;
    
    if (sum[i] > .01) {
      // second condition generates an asteroid if true, so every 1 in 100 is an asteroid rather than a star
      particles.add(new Particle(float(i),random(100)>=99));
    }
  }
  
  // update each particle
  for (int i = 0; i < particles.size(); i++) {
    particles.get(i).update();
  }
  
  // remove the particles if off screen
  for (int i = 0; i < particles.size(); i++) {
    if (particles.get(i).offScreen) {
      particles.remove(i);
      i--;
    }
  }
  
  
}

// function to generate the spinning hue wheel
color colorTest(float x, float y,float a) {
  
  // time variable used to modify the fade to white
  float time = (timePassed-colorTimeStart) / 1000;
  
  // calculate the distance from this point to the centre of the circle
  PVector toCenter = new PVector(0.5-x/columns,0.5-y/rows);
  // find the angle of this point to the center - add time and smooth amp, so that it is spinning but also affected by the sound
  float angle = smoothAmp*2 + time + atan2(toCenter.x, toCenter.y);
  // modify the radius, or intensity of the hue based on time
  float radius = new PVector(0,0).dist(toCenter)*2 * ((20 - (time))/5);
  // output colour storing
  PVector col = new PVector((angle/2/PI)+0.5,radius,1.0);
  
  // use HSB to make this rainbow calculation much simpler
  colorMode(HSB);
  color c = color(col.x*255%255,col.y*255,col.z*255, a);
  colorMode(RGB);
  // return the colour
  return c;
  
}

// smoothstep function taken from the book of shaders: https://thebookofshaders.com/glossary/?search=smoothstep
float smoothstep(float edge0, float edge1, float x) {
  float t = min(max((x-edge0) / (edge1 - edge0),0.),1.);
  return t * t * (3 - 2 * t);
}
