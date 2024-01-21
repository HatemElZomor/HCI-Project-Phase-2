import processing.sound.*; //<>//
import TUIO.*;

TuioProcessing tuioClient;

////////////////////////////////////////////

// Socket //

import java.net.Socket;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;

Socket socket;
BufferedReader reader;
PrintWriter writer;
String message;

////////////////////////////////////////////

float cursor_size = 15;
float object_size = 60;
float table_size = 760;
float scale_factor = 1;
PFont font;

boolean verbose = false;
boolean callback = true;

////////////////////////////////////////////

// Global Vars
SoundFile[] songs;

// Audio effects
Reverb reverb1;
Reverb reverb2;
Reverb reverb3;
BandPass bandPass1;
BandPass bandPass2;
BandPass bandPass3;

//

PFont timeFont;

//

////////////////////////////////////////////

// CONTEXT //

// Marker 0 - Hatem
boolean isMarkerPresent0 = false;

// Marker 1 - Ziad
boolean isMarkerPresent1 = false;

// Marker 2 - Ghyth
boolean isMarkerPresent2 = false;

////////////////////////////////////////////

// DJ Vars //

// Marker 3 - Volume
float storedOrientation3 = 0; // Amplitude
boolean isMarkerPresent3 = false;

// Marker 4 - Reverb
float storedX4 = 0; // Damping & Room Size
float storedY4 = 0; //
boolean isMarkerPresent4 = false;

// Marker 5 - Band pass filter
float storedX5 = 0; // Frequency
float storedY5 = 0; // Bandwidth
boolean isMarkerPresent5 = false;

// Song selected
int index = -1;

// Trigger Pause/Resume
String prevMessage = "";

////////////////////////////////////////////

// Visualizations //
String person = "no one";
String song = "Nothing Played";
String status = "N/A";

float rotationCircleRadius = 30;
float rotationTextSize = 12; // You can adjust the radius as needed

////////////////////////////////////////////

void setup()
{
  
  timeFont = createFont("Arial", 16);
  ///////////////////////////////////////////

  // SOCKET //
  String serverIP = "127.0.0.1"; // Server IP address
  int serverPort = 5555; // Server port

  try {
    // Connect to the server
    socket = new Socket(serverIP, serverPort);
    println("Connected to server at " + serverIP + ":" + serverPort);

    // Initialize reader and writer
    reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
    writer = new PrintWriter(socket.getOutputStream(), true);
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  ///////////////////////////////////////////

  // GUI setup //
  noCursor();
  size(1450/2, 1080/2);
  noStroke();
  fill(0);

  // periodic updates //
  if (!callback) {
    frameRate(60);
    loop();
  } else noLoop(); // or callback updates

  font = createFont("Arial", 18);
  scale_factor = height/table_size;

  // finally we create an instance of the TuioProcessing client
  // since we add "this" class as an argument the TuioProcessing class expects
  // an implementation of the TUIO callback methods in this class (see below)
  tuioClient  = new TuioProcessing(this);

  ///////////////////////////////////////////////////

  // Initialize and load songs
  songs = new SoundFile[3]; // Assuming you have 3 different songs
  songs[0] = new SoundFile(this, "Led Zeppelin - Stairway To Heaven (Official Audio).mp3");
  songs[1] = new SoundFile(this, "Pink Floyd - _Hey You_.mp3");
  songs[2] = new SoundFile(this, "Pink Floyd - High Hopes (Official Music Video HD).mp3");
  // Create effect objects
  reverb1 = new Reverb(this);
  reverb2 = new Reverb(this);
  reverb3 = new Reverb(this);
  bandPass1 = new BandPass(this);
  bandPass2 = new BandPass(this);
  bandPass3 = new BandPass(this);

  // Default Song
  // songs[0].loop();

  ///////////////////////////////////////////////////
}



void draw()
{
  // Socket Loop (Pause/Play) //

  try {
    if (reader.ready()) {
      message = reader.readLine();
      println("Received from server: " + message);

      // Pause & Play
      // Check if the message has changed from "1" to "0"
      if (prevMessage.equals("1") && message.equals("0")) {
        pauseSong(index);
        status = "Paused";
        println("Paused");
      }

      // Check if the message has changed from "0" to "1"
      if (prevMessage.equals("0") && message.equals("1")) {
        playSong(index);
        println("Playing");
      }

      // Update prevMessage for the next iteration
      prevMessage = message;
    }
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  // Display the received message
  // text("Gesture Status: " + message, 10, 50);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Display local time in the top right corner
  fill(0);
  textFont(timeFont, 16);
  textAlign(RIGHT, TOP);
  String currentTime = getCurrentTime();
  
  // Check if the current time is after 5 pm (17:00)
  int currentHour = Integer.parseInt(currentTime.substring(0, 2));
  if (currentHour >= 17) {
    background(70); // Set background to Dark Mode
  } else {
    background(255); // Set background to white
  }
  
  text(currentTime, width - 10, 30);
  
  textFont(font, 18*scale_factor);
  float obj_size = object_size*scale_factor;
  float cur_size = cursor_size*scale_factor;

  ArrayList<TuioObject> tuioObjectList = tuioClient.getTuioObjectList();
  for (int i=0; i < tuioObjectList.size(); i++) {

    /////////////////////////////////////////////////////////////////////////////////////////////////

    TuioObject tobj = tuioObjectList.get(i);
    float x = tobj.getScreenX(width);
    float y = tobj.getScreenY(height);
    float rotation = tobj.getAngle();

    // DJ App Here //

    // Marker 0 - Hatem
    if (tobj.getSymbolID() == 0) {
      if (isMarkerPresent0 == false) {
        playSong(0);
        pauseSong(1);
        pauseSong(2);
        isMarkerPresent0 = true;
        isMarkerPresent1 = false;
        isMarkerPresent2 = false;
        person = "Hatem";
        song = "Led Zeppelin - Stairway To Heaven";
        index = 0;
      }
    }

    // Marker 1 - Ziad
    if (tobj.getSymbolID() == 1) {
      if (isMarkerPresent1 == false) {
        pauseSong(0);
        playSong(1);
        pauseSong(2);
        isMarkerPresent0 = false;
        isMarkerPresent1 = true;
        isMarkerPresent2 = false;
        person = "Ziad";
        song = "Pink Floyd - Hey You";
        index = 1;
      }
    }

    // Marker 2 - Ghyth
    if (tobj.getSymbolID() == 2) {
      if (isMarkerPresent2 == false) {
        pauseSong(0);
        pauseSong(1);
        playSong(2);
        isMarkerPresent0 = false;
        isMarkerPresent1 = false;
        isMarkerPresent2 = true;
        person = "Ghyth";
        song = "Pink Floyd - High Hopes";
        index = 2;
      }
    }

    // Marker 3 - Volume
    if (tobj.getSymbolID() == 3) {
      storedOrientation3 = rotation;
      // Rotation
      float volume = map(storedOrientation3, 0, 6.3, 0.0, 1.0);
      songs[0].amp(volume);
      songs[1].amp(volume);
      songs[2].amp(volume);
    }

    // Marker 4 - Reverb
    if (tobj.getSymbolID() == 4) {
      storedX4 = x;
      storedY4 = y;

      // X
      float roomSize = map(storedX4, 0, width, 0, 1.0);
      reverb1.room(roomSize);
      float damping = map(storedX4, 0, width, 0, 1.0);
      reverb1.damp(damping);
      reverb2.damp(damping);
      reverb3.damp(damping);

      // Y
      float effectStrength = map(storedY4, 0, height, 0, 1.0);
      reverb1.wet(effectStrength);
      reverb2.wet(effectStrength);
      reverb3.wet(effectStrength);

      // Reverb
      reverb1.process(songs[0]);
      reverb2.process(songs[1]);
      reverb3.process(songs[2]);
    }

    // Marker 5 - Frequency and Filter
    if (tobj.getSymbolID() == 5) {
      storedX5 = x;
      storedY5 = y;

      // X
      float frequency = map(storedX5, 0, width, 20, 10000);

      // Y
      float bandwidth = map(storedY5, 0, height, 1000, 100);

      // Set frequency and bandwidth for each filter
      bandPass1.freq(frequency);
      bandPass1.bw(bandwidth);

      bandPass2.freq(frequency);
      bandPass2.bw(bandwidth);

      bandPass3.freq(frequency);
      bandPass3.bw(bandwidth);

      // Process each sound source with its respective filter
      bandPass1.process(songs[0]);
      bandPass2.process(songs[1]);
      bandPass3.process(songs[2]);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////

    // Visualizations //

    if (tobj.getSymbolID() == 3) {
      // Map rotation to fill the circle based on the angle
      float mappedFill = map(rotation, 0, TWO_PI, 0, 1);

      // Interpolate between red and green based on completion
      color circleColor = lerpColor(color(255, 0, 0), color(0, 255, 0), mappedFill);

      // Draw filled circle
      fill(circleColor);
      noStroke();
      beginShape();
      for (float angle = 0; angle <= rotation; angle += 0.01) {
        float xPos = x + cos(angle) * rotationCircleRadius;
        float yPos = y + sin(angle) * rotationCircleRadius;
        vertex(xPos, yPos);
      }
      endShape(CLOSE);

      //// Draw rotation text
      //fill(0);
      //textSize(rotationTextSize);
      textAlign(CENTER, CENTER);
      //text(nf(degrees(rotation), 0, 2) + "°", x, y + rotationCircleRadius + rotationTextSize); // Display rotation in degrees

      // Draw volume text
      float volume = map(rotation, 0, TWO_PI, 0, 100); // Assuming a range of 0 to 100 for volume
      text("Volume: " + nf(volume, 0, 2), x, y + rotationCircleRadius + rotationTextSize * 2);
    }

    if (tobj.getSymbolID() == 4) {
      // X,Y
      fill(255, 0, 0);
      rect(x, 0, 5, height);
      rect(0, y, width, 5);

      // Draw Square and Name
      stroke(0);
      fill(0, 0, 0);
      pushMatrix();
      translate(x, y);
      rect(-obj_size/2, -obj_size/2, obj_size, obj_size);
      popMatrix();
      fill(255);
      textAlign(CENTER, CENTER);
      text("Reverb", x, y);
    }

    if (tobj.getSymbolID() == 5) {
      // X,Y
      fill(0, 255, 0);
      rect(x, 0, 5, height);
      rect(0, y, width, 5);

      // Draw Square and Name
      stroke(0);
      fill(0, 0, 0);
      pushMatrix();
      translate(x, y);
      rect(-obj_size/2, -obj_size/2, obj_size, obj_size);
      popMatrix();
      fill(255);
      textAlign(CENTER, CENTER);
      text("Filter", x, y);
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////
  }

  // More visualizations
  fill(0);
  textSize(16);
  textAlign(RIGHT, BOTTOM);
  text("Person: " + person + "\nSong: " + song + "\nStatus: " + status, width-5, height-5);

  // Graph
  stroke(1);
  line(0, 10, width, 10); // Horizontal line (x-axis)
  line(10, 0, 10, height); // Vertical line (y-axis)

  // Draw min and max labels for the lines
  fill(0);
  textSize(12);
  textAlign(LEFT, BOTTOM);
  text("Max", width-30, 25);
  text("Min", 15, 25);
  text("Max", 15, height-5);

  ArrayList<TuioCursor> tuioCursorList = tuioClient.getTuioCursorList();
  for (int i=0; i < tuioCursorList.size(); i++) {
    TuioCursor tcur = tuioCursorList.get(i);
    ArrayList<TuioPoint> pointList = tcur.getPath();

    if (pointList.size() > 0) {
      stroke(0, 0, 255);
      TuioPoint start_point = pointList.get(0);
      for (int j=0; j < pointList.size(); j++) {
        TuioPoint end_point = pointList.get(j);
        line(start_point.getScreenX(width), start_point.getScreenY(height), end_point.getScreenX(width), end_point.getScreenY(height));
        start_point = end_point;
      }
    }
  }

  ArrayList<TuioBlob> tuioBlobList = tuioClient.getTuioBlobList();
  for (int i=0; i < tuioBlobList.size(); i++) {
    TuioBlob tblb = tuioBlobList.get(i);
    stroke(0);
    fill(0);
    pushMatrix();
    float x = tblb.getScreenX(width);
    float y = tblb.getScreenY(height);
    translate(x, y);
    rotate(tblb.getAngle());
    ellipse(-1*tblb.getScreenWidth(width)/2, -1*tblb.getScreenHeight(height)/2, tblb.getScreenWidth(width), tblb.getScreenWidth(width));
    popMatrix();
    fill(255);
    text("" + tblb.getBlobID(), x, y);
  }
}






// Socket Function //

void stop() {
  // Close the socket and streams when the sketch is closed
  try {
    reader.close();
    writer.close();
    socket.close();
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  super.stop();
}

// Function to play Song //

void playSong(int songIndex) {
  status = "Playing";
  songs[songIndex].loop(); // Play the new song
}

// Function to stop Song

void pauseSong(int songIndex) {
  songs[songIndex].pause(); // Play the new song
}


// --------------------------------------------------------------
// these callback methods are called whenever a TUIO event occurs
// there are three callbacks for add/set/del events for each object/cursor/blob type
// the final refresh callback marks the end of each TUIO frame

// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {
  if (verbose) println("add obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  if (verbose) println("set obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
    +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  if (verbose) println("del obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}

// --------------------------------------------------------------
// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  if (verbose) println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
  //redraw();
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  if (verbose) println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
    +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
  //redraw();
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  if (verbose) println("del cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
  //redraw()
}

// --------------------------------------------------------------
// called when a blob is added to the scene
void addTuioBlob(TuioBlob tblb) {
  if (verbose) println("add blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea());
  //redraw();
}

// called when a blob is moved
void updateTuioBlob (TuioBlob tblb) {
  if (verbose) println("set blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea()
    +" "+tblb.getMotionSpeed()+" "+tblb.getRotationSpeed()+" "+tblb.getMotionAccel()+" "+tblb.getRotationAccel());
  //redraw()
}

// called when a blob is removed from the scene
void removeTuioBlob(TuioBlob tblb) {
  if (verbose) println("del blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+")");
  //redraw()
}

// --------------------------------------------------------------
// called at the end of each TUIO frame
void refresh(TuioTime frameTime) {
  if (verbose) println("frame #"+frameTime.getFrameID()+" ("+frameTime.getTotalMilliseconds()+")");
  if (callback) redraw();
}

String getCurrentTime() {
  // Create a Calendar instance
  java.util.Calendar calendar = java.util.Calendar.getInstance();

  // Extract hours, minutes, and seconds from the Calendar instance
  int hours = calendar.get(java.util.Calendar.HOUR_OF_DAY);
  int minutes = calendar.get(java.util.Calendar.MINUTE);
  int seconds = calendar.get(java.util.Calendar.SECOND);

  // Return the formatted time as a string
  return nf(hours, 2) + ":" + nf(minutes, 2) + ":" + nf(seconds, 2);
}
