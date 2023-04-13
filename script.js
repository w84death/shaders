/*
 * 64K/4K HTML5 WEBGL INTRO TOOL
 * by Krzysztof Krystian Jankowski / P1X
 * */

// HTML ELEMENTS BINDING
const landingPage = document.getElementById("landingPage");
const startButton = document.getElementById("startButton");
const canvas = document.getElementById("glCanvas");
const gl = canvas.getContext("webgl");
const shaderPanel = document.getElementById("shaderPanel");
const audio = document.getElementById("audio");
const playStopBtn = document.getElementById("playStopBtn");
const seekBar = document.getElementById("seekBar");
const currentTime = document.getElementById("currentTime");
const resolutionSelect = document.getElementById("resolutionSelect");
const fullscreenCheckbox = document.getElementById("fullscreenCheckbox");
const fps = document.getElementById("fps");
const fpsCounter = document.getElementById("fpsCounter");
const frameCounter = document.getElementById("frameTime");

if (!gl) {
  alert("WebGL not supported. Please use a compatible browser.");
}

// START INTRO BUTTON
startButton.addEventListener("click", () => {
  landingPage.style.display = "none";
  glCanvas.hidden = false;
  shaderPanel.hidden = false;
  audioControls.hidden = false;
  fps.hidden = false;
  initWebGL();
});

async function initWebGL() {

  // BIND AUDIO STUFF
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const audioSource = audioContext.createMediaElementSource(audio);
  const analyser = audioContext.createAnalyser();
  analyser.fftSize = 1024;
  audioSource.connect(analyser);
  audioSource.connect(audioContext.destination);

  audio.addEventListener("loadedmetadata", () => {
    seekBar.max = audio.duration;
  });

  audio.addEventListener("timeupdate", () => {
    seekBar.value = audio.currentTime;
  });

  function startAudio(){
    audio.play();
    seekBar.max = audio.duration;
    playStopBtn.textContent = "Stop";
  }

  playStopBtn.addEventListener("click", () => {
    if (audio.paused) {
      startAudio();
    } else {
      audio.pause();
      playStopBtn.textContent = "Play";
    }
  });

  seekBar.addEventListener("input", () => {
    audio.currentTime = seekBar.value;
  });

  // SET RESOLUTION
  function resizeCanvas() {
    const resolutionScale = parseFloat(resolutionSelect.value);
    canvas.width = window.innerWidth * resolutionScale;
    canvas.height = window.innerHeight * resolutionScale;
    gl.viewport(0, 0, canvas.width, canvas.height);
  }
  window.addEventListener("resize", resizeCanvas);

  // VERTEX SHADER (JUST SETING UV)
  const vertexShaderSource = `
    attribute vec2 a_position;
    varying vec2 v_uv;

    void main() {
      gl_Position = vec4(a_position, 0.0, 1.0);
      v_uv = a_position;
    }
  `;

  // FRAGMENT SHADER - THE INTRO!
  const fragmentShaderSource = await fetch("shader.glsl").then(response => response.text());

  // PUT SOURCES INTO UI
  shaderPanel.textContent = fragmentShaderSource;

  // COMPILE SHADER
  function createShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      alert("Error compiling shader: " + gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  // CREATE GL ENVIRONMENT WITH ONE PLANE FOR THE SHADER
  const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  gl.useProgram(program);
  const positionAttributeLocation = gl.getAttribLocation(program, "a_position");
  const positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  const positions = [-1, -1,1, -1, -1, 1,1, 1 ];
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(positionAttributeLocation);
  gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);

  // UNIFORMS
  const timeUniformLocation = gl.getUniformLocation(program, "u_time");
  const resolutionUniformLocation = gl.getUniformLocation(program, "u_resolution");
  const frequencyUniformLocation = gl.getUniformLocation(program, "u_fft");

  const fftIndex = 10;
  const fftData = new Uint8Array(analyser.frequencyBinCount);

  let frameCount = 0;
  let lastUpdateTime = 0;

  function render() {

    // CALCULATE FPS AND FRAME TIME
    frameCount++;
    const currentTime = performance.now();
    const deltaTime = currentTime - lastUpdateTime;
    if (deltaTime > 1000) {
      const fps = (frameCount / deltaTime) * 1000;
      const frameTime = 1000 / fps;
      fpsCounter.textContent = fps.toFixed(2);
      frameCounter.textContent = frameTime.toFixed(2);
      frameCount = 0;
      lastUpdateTime = currentTime;
    }

    // CALCULATE FFT
    analyser.getByteFrequencyData(fftData);
    const fftValue = (
      fftData[fftIndex]/255 +
      fftData[fftIndex-4]/255 +
      fftData[fftIndex+4]/255 )/3;

    // SYNC INTRO TIME WITH AUDIO TRACK
    const elapsedTime = audio.currentTime;
    currentTime.textContent = elapsedTime.toFixed(2);

    // SEND UNIFORMS
    gl.uniform1f(timeUniformLocation, elapsedTime);
    gl.uniform2f(resolutionUniformLocation, canvas.width, canvas.height);
    gl.uniform1f(frequencyUniformLocation, fftValue);

    // DRAW A FRAME
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    requestAnimationFrame(render);
  }

  // START INTRO
  resizeCanvas();
  render();
  if (fullscreenCheckbox.checked) canvas.requestFullscreen();
  startAudio();
}

