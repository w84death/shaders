  async function main() {
    const canvas = document.getElementById("glCanvas");
    const gl = canvas.getContext("webgl");
    const shaderPanel = document.getElementById("shaderPanel");
    const audio = document.getElementById("audio");
    const playStopBtn = document.getElementById("playStopBtn");
    const seekBar = document.getElementById("seekBar");
    const currentTime = document.getElementById("currentTime");

    if (!gl) {
      alert("WebGL not supported. Please use a compatible browser.");
    }

    function resizeCanvas() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      gl.viewport(0, 0, canvas.width, canvas.height);
    }

    window.addEventListener("resize", resizeCanvas);
    resizeCanvas();

    const vertexShaderSource = `
      attribute vec2 a_position;
      varying vec2 v_uv;

      void main() {
        gl_Position = vec4(a_position, 0.0, 1.0);
        v_uv = a_position;
      }
    `;

    const fragmentShaderSource = await fetch("shader.glsl").then(response => response.text());
    shaderPanel.textContent = fragmentShaderSource;

      audio.addEventListener("loadedmetadata", () => {
        seekBar.max = audio.duration;
      });

      audio.addEventListener("timeupdate", () => {
        seekBar.value = audio.currentTime;
      });

      playStopBtn.addEventListener("click", () => {
        if (audio.paused) {
          audio.play();
          seekBar.max = audio.duration;
          playStopBtn.textContent = "Stop";
} else {
audio.pause();
playStopBtn.textContent = "Play";
}
});

seekBar.addEventListener("input", () => {
    audio.currentTime = seekBar.value;
  });


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
    const timeUniformLocation = gl.getUniformLocation(program, "u_time");
    const resolutionUniformLocation = gl.getUniformLocation(program, "u_resolution");
    const startTime = performance.now() * 0.001;

    function drawScene() {
      const elapsedTime = audio.currentTime;
      currentTime.textContent = elapsedTime.toFixed(2);

      gl.uniform1f(timeUniformLocation, elapsedTime);
      gl.uniform2f(resolutionUniformLocation, canvas.width, canvas.height);

      gl.clearColor(0.0, 0.0, 0.0, 1.0);
      gl.clear(gl.COLOR_BUFFER_BIT);

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

      requestAnimationFrame(drawScene);
    }

    drawScene();
    }

    main();
