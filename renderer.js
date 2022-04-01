;(function(){
"use strict"

// Set up global program data
window.addEventListener("load", setupWebGL, false);
var gl, program, winform, minwid, maxwid, nowlck, centerlck, qlck, plck, rotlck;
var progStart = new Date();
const V_COUNT = (2**12);
const K_COUNT = 5;
const PI = 3.141592653589;
const PITCH = PI/4;
const YAW = PI/4;
const ROLL = PI/6;
const VAR_FREQ_SCALAR = Math.exp(-PI);
const P_VAR_FREQ = 2  * VAR_FREQ_SCALAR;
const Y_VAR_FREQ = 3  * VAR_FREQ_SCALAR;
const R_VAR_FREQ = PI * VAR_FREQ_SCALAR;
const P_VAL = [-9, 5, -5, 2, -3];
const Q_VAL = [7, -7, 3, -3, 2];


async function setupWebGL (evt) {
  // Create a rendering context. In other words, create the base canvas to draw
  // the shader onto, pulling metadata about the setup like the maximum 
  // canvas resolution.
  window.removeEventListener(evt.type, setupWebGL, false);
  if (!(gl = getRenderingContext()))
    return;
  
  // Pull the scripts from the data provdided in the base HTML document at the
  // vertex-shader and fragment-shader id's
  var vsource = document.querySelector("#vertex-shader");
  var fsource = document.querySelector("#fragment-shader");

  // Compile the vertex shader through the webgl system. If the shader doesn't
  // compile nicely, display the error and halt.
  var vertexShader = gl.createShader(gl.VERTEX_SHADER);
  // Pull the script from the hosted location. This is done for ease of
  // programming (glsl extension and syntax-highlighting and such), and is
  // needed to be done like this due to the src tag usage.
  await fetch(vsource.src).then(response => response.text())
    .then(data => {
      gl.shaderSource(vertexShader, data);
      gl.compileShader(vertexShader);
    });
  // If the shader reports that it could not compile correctly, stop the program
  // and display the error that was stored in the webgl system.
  if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
    var cerrLog = gl.getShaderInfoLog(vertexShader);
    cleanup();
    document.querySelector("p").innerHTML =
      "Vertex shader did not compile successfully.\n"
      + "Error log:\n" + cerrLog;
    return;
  }

  // Do the exact same as above, but for a fragment shader instead.
  var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
  await fetch(fsource.src).then(response => response.text())
    .then(data => {
      gl.shaderSource(fragmentShader, data);
      gl.compileShader(fragmentShader);
    });
  if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
    var cerrLog = gl.getShaderInfoLog(fragmentShader);
    cleanup();
    document.querySelector("p").innerHTML = 
      "Fragment shader did not compile successfully.\n"
      + "Error log:\n" + cerrLog;
    return;
  }

  // Slap the shaders together with some glue.
  program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  winform = gl.getUniformLocation(program, "winsize");
  minwid = gl.getUniformLocation(program, "minwid");
  maxwid = gl.getUniformLocation(program, "maxwid");
  nowlck = gl.getUniformLocation(program, "now");
  centerlck = gl.getUniformLocation(program, "center");
  plck = gl.getUniformLocation(program, "pval");
  qlck = gl.getUniformLocation(program, "qval");
  rotlck = gl.getUniformLocation(program, "rotation");
  gl.uniform2f(winform, gl.drawingBufferWidth, gl.drawingBufferHeight);
  gl.uniform1f(minwid, smallestWinSize());
  gl.uniform1f(nowlck, timeFloat());
  gl.uniform1f(maxwid, largestWinSize());
  gl.uniform2f(centerlck, 0, 0);
  gl.uniform1f(plck, P_VAL);
  gl.uniform1f(qlck, Q_VAL);
  gl.uniform3f(rotlck, PITCH,YAW,ROLL);
  
  // Now that the program is all glued together, get rid of the compiled shader
  // chunks. We wouldn't want to eat up the ever-so-valueable resources would we?
  gl.detachShader(program, vertexShader);
  gl.detachShader(program, fragmentShader);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);

  // Another error trap that halts the program and displays what the fuck is
  // goin on.
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    var linkErrLog = gl.getProgramInfoLog(program);
    cleanup();
    document.querySelector("p").innerHTML = 
      "Shader program did not link successfully. "
      + "Error log: " + linkErrLog;
    return;
  } 

  // Attach the base shader attributes for the shaders to know what is going on
  // in the system.
  initializeAttributes();

  // Load the compiled and linked program, then make the program render itself at
  // approximately 30 fps. The extra code is needed to keep the canvas locked to
  // the size of the displaying window.
  gl.useProgram(program);
  setInterval(function() {
    var canvas = document.querySelector("canvas");
    if (canvas.width != canvas.clientWidth) {
      canvas.width = canvas.clientWidth;
    }
    if (canvas.height != canvas.clientHeight) {
      canvas.height = canvas.clientHeight;
    }

    var gl = canvas.getContext("webgl") 
      || canvas.getContext("experimental-webgl");
    
    if (!gl) {
      var paragraph = document.querySelector("p");
      paragraph.innerHTML = "Failed to get WebGL context."
        + "Your browser or device may not support WebGL.";
      
      return null;
    }

    gl.viewport(0, 0, 
      gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.uniform2f(winform, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.uniform1f(minwid, smallestWinSize());
    gl.uniform1f(maxwid, largestWinSize());
    gl.uniform1f(nowlck, timeFloat());
    gl.uniform2f(centerlck, 0., 0.);
    gl.uniform1f(plck, P_VAL);
    gl.uniform1f(qlck, Q_VAL);
    gl.uniform3f(rotlck, PITCH + ((PI/2) * Math.sin(P_VAR_FREQ*timeFloat())), 
      YAW + ((PI/2) * Math.sin(Y_VAR_FREQ * timeFloat())), 
      ROLL + ((PI/2) * Math.sin(R_VAR_FREQ * timeFloat())));

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 4, gl.FLOAT, false, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.drawArrays(gl.POINTS, 0, K_COUNT*V_COUNT);
  }, [(1./30.)*1000.]);
}

// Get the smallest of the two window dimensions for use in constant output ratio
// display for shaders.
function smallestWinSize() {
  // Compare the width vs the height and return the smallest.
  if (gl.drawingBufferWidth < gl.drawingBufferHeight) {
    return gl.drawingBufferWidth;
  }
  return gl.drawingBufferHeight;
}
function largestWinSize() {
  if (gl.drawingBufferWidth < gl.drawingBufferHeight) {
    return gl.drawingBufferHeight;
  }
  return gl.drawingBufferWidth;
}
function timeFloat() {
  var currentDate = new Date();
  var delta = currentDate - progStart;

  return delta / 1000.;
}

// Sets up the attributes for the shaders that are running. This is used before
// everything is actually up and running (but after compilation), and is basically
// the anchor to the base of the shaders.
var posbuf;
function initializeAttributes() {
  // Create the rotational coordinates for the vertex buffer
  var jspos = Array(K_COUNT*4*V_COUNT);
  for (let k = 0; k < K_COUNT; k += 1) {
    var offset = k * (4*V_COUNT);
    for (let i = 0; i < 4*V_COUNT; i += 4) {
      var localoff = offset+i;
      jspos[localoff] = (i / (4*V_COUNT))-1.;
      jspos[localoff+1] = k;
      jspos[localoff+2] = P_VAL[k];
      jspos[localoff+3] = Q_VAL[k];
    }
  }

  // Create the base buffer for the vertices
  posbuf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, posbuf);

  // Apply the buffer to the gl program
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(jspos), gl.STATIC_DRAW);
	gl.enable(gl.DEPTH_TEST);
}

// Make the main program null, delete the running program, and delete the main
// shader buffer.
function cleanup() {
  gl.useProgram(null);
  if (posbuf)
    gl.deleteBuffer(posbuf);
  if (program) 
    gl.deleteProgram(program);
}

// Get the rendering context of the screen and flush. The system constantly does
// this, but doesn't clear the whole screen to do it. This function is more of
// an initialization thing.
function getRenderingContext() {
  var canvas = document.querySelector("canvas");
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;

  var gl = canvas.getContext("webgl", {preserveDrawingBuffer: true});
  
  if (!gl) {
    var paragraph = document.querySelector("p");
    paragraph.innerHTML = "Failed to get WebGL context."
      + "Your browser or device may not support WebGL.";
    
    return null;
  }

  gl.viewport(0, 0, 
    gl.drawingBufferWidth, gl.drawingBufferHeight);
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);
  return gl;
}
})();