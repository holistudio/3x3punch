// Modified version of a workshop file by Cedric Honnet:
// https://github.com/honnet/ITP
// ...who modified a version from art work by Andreas Schlegel:
// https://github.com/sojamo/Movement-of-Things/


import java.util.*;
import oscP5.*;
import controlP5.*;
import static controlP5.ControlP5.*;

OscP5 osc;
ControlP5 cp;

float objRecordX; // x-coordinate of the last shape generated from accelerometer. also the total distance "covered" by all shapes generated
int keyVertex;
int[] vertexAdjacents;

PrintWriter writer;
PrintWriter csv;

void setup() {
  fullScreen(P3D);
  //size(1280, 600, P3D);

  smooth(8);
  hint(DISABLE_DEPTH_TEST);
  osc = new OscP5(this, 4559);
  cp = new ControlP5(this); // controller library for building GUI on top of processing
  background(0);
  noStroke();
  
  writer = createWriter("extract.obj"); // write to a 3D OBJ file for further manipulation in 3D geometry software
  csv = createWriter("sensor-data.csv"); // write the wireless accelerometer data to a CSV for further analysis
  keyVertex=1; //first vertex index for obj file
  vertexAdjacents= new int[]{0,1,2,3}; // used for figuring out corner indices for writing the rectangle geometry to obj file
}

void draw() {
  noStroke();
  fill(0, 255);
  rect(0, 0, width, height);
  render();
}

void mouseClicked() {
  csv.close();
  writer.close();
  exit();
}

boolean autoRotate = true;

void keyPressed() {
  autoRotate = !autoRotate;
}


float spacing = 1; /* spacing between each visual element */
float scl = 0.2; /* zoom factor while rendering */
int len;
List<Data> log = new ArrayList();


void render() {
  if (log.size()<=0) {
    return;
  }

  /* render visual elements into the 3D scene without
   * clearing the render buffer while the program is running.
   */
  lights();
  pushMatrix();
  translate(width/4, height/2);
  scale(scl);
  translate(-objRecordX*0.25, 0); //shift objects a quarter of the total 
  
  float d=0.0; //depth of rectangle
  float h=0.0; // height of rectangle
  float aMag=0.0; // magnitude of acceleration vector 
  float azWOG=0; //z-acceleration WithOut Gravity
  float angle=0; // angle of rotation of the rectangle about the x-axis
  float tilt=0; // angle of rotation of rectangle about z axis
  
  for (int i=1; i<log.size(); i++) {
    Data data = log.get(i);
    azWOG = abs(data.az)-1;
    aMag = sqrt((data.ax*data.ax)+(data.ay*data.ay)+(azWOG*azWOG));
    d = map(aMag,0,4,200,900);
    h = d;
    spacing = 2*pow(aMag,5)+10;
    translate(spacing, 0);
    angle=radians(map(data.rx,-500,500,-45,45));
    tilt=radians(map(abs(azWOG),0,1,0,45));
    pushMatrix(); //pushes the coordinate system of the drawn element
    rotateX(angle);
    rotateZ(tilt);
    
    noFill();
    strokeWeight(4);
    stroke(255);
    
    box(1, h, d);
    
    //on the last data recording on the log, write the rectangle's corner coordinates to an *.obj file.
    if(i==(log.size()-1)){
      objRecordX+= spacing;
      writer.println("v "+str(objRecordX+(h*cos(angle)+d*sin(angle))*sin(tilt)/2)+" "+str((d*cos(angle)-h*sin(angle))/2)+" "+str((h*cos(angle)+d*sin(angle))*cos(tilt)/2));
      writer.println("v "+str(objRecordX-(h*cos(angle)-d*sin(angle))*sin(tilt)/2)+" "+str((d*cos(angle)+h*sin(angle))/2)+" "+str(-(h*cos(angle)-d*sin(angle))*cos(tilt)/2));
      writer.println("v "+str(objRecordX-(h*cos(angle)+d*sin(angle))*sin(tilt)/2)+" "+str(-(d*cos(angle)-h*sin(angle))/2)+" "+str(-(h*cos(angle)+d*sin(angle))*cos(tilt)/2));
      writer.println("v "+str(objRecordX+(h*cos(angle)-d*sin(angle))*sin(tilt)/2)+" "+str(-(d*cos(angle)+h*sin(angle))/2-h*cos(tilt)/2)+" "+str((h*cos(angle)-d*sin(angle))*cos(tilt)/2));
      
      for (int j = 0; j < 4; j++) {
        writer.println("vt 1 1");
      }
      for (int j = 0; j < 4; j++) {
        writer.println("vn 1 0 0");
      }
      writer.print("f ");
      for (int k=0; k<vertexAdjacents.length;k++){
        for (int l=0; l<3; l++){
          writer.print(str(keyVertex+vertexAdjacents[k]));
          if(l<2){
            writer.print("/");
          }
          else{
            writer.print(" ");
          }
        }
      }
      writer.print("\n");
      keyVertex+=4;
    }
    popMatrix();
  }
  popMatrix();
}


class Data {
  float ax, ay, az, rx, ry, rz;
  public String toString() {
    return (str(ax)+","+str(ay)+","+str(az)+","+str(rx)+","+str(ry)+","+str(rz)+"\n");
  }
}



void oscEvent(OscMessage m) {
  if (log.size()==800) {
    log.remove(0);
  }
  if (m.addrPattern().startsWith("/IMU")) {
    Data data = new Data();
    data.ax = m.get(0).floatValue();
    data.ay = m.get(1).floatValue();
    data.az = m.get(2).floatValue();
    data.rx = m.get(3).floatValue();
    data.ry = m.get(4).floatValue();
    data.rz = m.get(5).floatValue(); 
    
    //println(data);
    csv.print(data);
    log.add(data);
  }
}
