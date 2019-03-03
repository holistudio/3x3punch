const videoFile = ''; //filepath of the video you want feed into PoseNet
//Indices of the bodyparts recognized by PoseNet (see PoseNet Documentation)
var keyPtsOfInterest = [0,5,9,13,15,16,14,10,6];

//in-video animation parameters
let spacing = 10; //spacing between shapes in the animation
let numDrawFrames = 10; // number of frames to draw shapes for in the animation

//video and PoseNet parameters
let video;
let poseNet;
let w = 1920;
let h = 1080;
let poses = [];
let poseShapes = [];


//OBJ file writer parameters
let writer;
const objRecordRate = 5; // record every 5 frames/shapes to the OBJ file
const objRecordSpacing = 50; // space shapes in 3D file every 50 units along x-axis of OBJ file
let objRecordX = 0; //x-coordinate of the shape to be writted to the OBJ file
let keyVertex = 1; //vertex counter for the OBJ file


function preload(){
  //write the shape's vertex coordinates to an OBJ file
  writer = createWriter('extract.obj');
}

function mouseClicked() {
  writer.close();
  writer.clear();
}

function gotPoses(estimatedPoses){
  poses = estimatedPoses;
}

function setup() {
  createCanvas(w, h);
  frameRate(10);
  video = createVideo(videoFile);
  video.size(w, h);

  poseNet = ml5.poseNet(video);

  poseNet.on('pose', function(results) {
    poses = results;
	});
  video.play();
  video.hide();

  noFill();
}

function draw() {

  background(0);
  // image(video, 0, 0, video.width, video.height);

  if(poses.length>=1){
    //for each pose detected
    var pose = poses[0].pose;

    //record newest shape
    let keyShape=[];
    // let numVertices = 0;
    for(var j = 0; j < keyPtsOfInterest.length;j++){
      //each key point and position is stored in variables
      var keypoint = pose.keypoints[keyPtsOfInterest[j]];
      var position = keypoint.position;

      if (keypoint.score > 0.03){
        // if keypoint's score is significant, store it in keyShape
        keyShape.push(position);
      }
    }

    //record shape to OBJ file for every nth frame, where n=objRecordRate
    if(frameCount % objRecordRate == 0){
      //if keyShape has more than 2 positions
      if(keyShape.length>2){
        //record keyShape's positions
        for (let i = 0; i < keyShape.length; i++) {
          writer.print(`v ${objRecordX} ${keyShape[i].x} ${video.height-keyShape[i].y}`);
        }
        //vt vn and f lines according to keyShape's length
        //vn 1 0 0 for every vertex
        //vt 1 1 for every vertex
        for (let i = 0; i < keyShape.length; i++) {
          writer.print(`vt 1 1`);
        }
        for (let i = 0; i < keyShape.length; i++) {
          writer.print(`vn 1 0 0`);
        }
        let n = keyVertex;
        //number of faces equals number of vertices -2 (keyShape's length - 2)
        for (let i = 0; i < keyShape.length-2; i++) {
          writer.print(`f ${n+1}/${n+1}/${n+1} ${n+2}/${n+2}/${n+2} ${keyVertex}/${keyVertex}/${keyVertex}`);
          n++;
        }
        keyVertex+= keyShape.length;
      }
      //always increment objRecordX by objRecordSpacing (so blank/invalid shapes will lead to blanks in the obj record)
      objRecordX = objRecordX + objRecordSpacing;

    }

    //if poseShapes length is less than numDrawFrames
    if(poseShapes.length<numDrawFrames){
      //add shape to end of array, as an array of positions
      poseShapes.push(keyShape);
    }

    //if the shapeArray length is numDrawFrames, draw all shapes
    if(poseShapes.length == numDrawFrames){
      
      //draw white lines with increasing opacity
      let shade = 0.1;

      for (let k = 0; k<poseShapes.length; k++){
        stroke(`rgba(255,255,255,${shade})`);
        beginShape();
        for (let l = 0; l<poseShapes[k].length; l++){
          vertex(poseShapes[k][l].x-(numDrawFrames*spacing), poseShapes[k][l].y);

        }
        endShape(CLOSE);
        translate(spacing,0);
        shade+= 0.2;
      }

      //remove shapeArray's first element (oldest)
      poseShapes.splice(0, 1);
    }
  }
}
