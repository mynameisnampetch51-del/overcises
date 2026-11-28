// Webcam + MediaPipe Pose Landmarker for the web build.
// Everything runs in the browser from files in ./mediapipe; no picture leaves it.

const base = new URL('./mediapipe/', import.meta.url).href;
let landmarker; // loaded once, then reused

async function load() {
  const { FilesetResolver, PoseLandmarker } = await import(base + 'vision_bundle.mjs');
  const files = await FilesetResolver.forVisionTasks(base + 'wasm');
  const create = (delegate) => PoseLandmarker.createFromOptions(files, {
    baseOptions: { modelAssetPath: base + 'pose_landmarker_lite.task', delegate },
    runningMode: 'VIDEO',
    numPoses: 1,
  });
  try {
    return await create('GPU');
  } catch (_) {
    return await create('CPU');
  }
}

// Fills `host` with the mirrored webcam and skeleton. Calls onPose for every
// new frame with 33 x (x px, y px, visibility), or null when nobody is seen.
function start(host, onPose, onError) {
  let stopped = false;
  let stream;
  const video = document.createElement('video');
  const canvas = document.createElement('canvas');
  video.muted = true;
  video.playsInline = true;
  host.style.position = 'relative';
  host.style.width = '100%';
  host.style.height = '100%';
  for (const el of [video, canvas]) {
    Object.assign(el.style, {
      position: 'absolute', inset: '0', width: '100%', height: '100%',
      objectFit: 'contain', transform: 'scaleX(-1)',
    });
    host.appendChild(el);
  }

  const release = () => stream?.getTracks().forEach((track) => track.stop());

  // Any failure, also in the middle of counting, must reach the app.
  const fail = (message, error) => {
    if (stopped) return;
    stopped = true;
    if (error) console.error(error);
    release();
    onError(message);
  };

  (async () => {
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 640 }, height: { ideal: 480 }, facingMode: 'user' },
        audio: false,
      });
    } catch (_) {
      fail('Camera not available. Allow the camera for this page.');
      return;
    }
    try {
      if (stopped) return release();
      // Unplugged, or permission taken back.
      stream.getTracks().forEach((track) =>
        track.addEventListener('ended', () => fail('The camera stopped.')));
      video.srcObject = stream;
      await video.play();
      landmarker ??= load();
      const model = await landmarker;
      const { DrawingUtils, PoseLandmarker } = await import(base + 'vision_bundle.mjs');
      const context = canvas.getContext('2d');
      const drawing = new DrawingUtils(context);
      let lastTime = -1;

      const frame = () => {
        if (stopped) return;
        try {
          readFrame();
        } catch (error) {
          return fail('Counting stopped because of an error.', error);
        }
        requestAnimationFrame(frame);
      };

      const readFrame = () => {
        if (video.currentTime !== lastTime && video.videoWidth > 0) {
          lastTime = video.currentTime;
          const width = video.videoWidth;
          const height = video.videoHeight;
          if (canvas.width !== width) {
            canvas.width = width;
            canvas.height = height;
          }
          const points = model.detectForVideo(video, performance.now()).landmarks[0];
          context.clearRect(0, 0, width, height);
          if (points) {
            drawing.drawConnectors(points, PoseLandmarker.POSE_CONNECTIONS, { color: '#4ADE80', lineWidth: 3 });
            drawing.drawLandmarks(points, { color: '#FFFFFF', radius: 2 });
            const data = new Float64Array(points.length * 3);
            points.forEach((p, i) => data.set([p.x * width, p.y * height, p.visibility ?? 0], i * 3));
            onPose(data);
          } else {
            onPose(null);
          }
        }
      };
      frame();
    } catch (error) {
      landmarker = undefined; // let the next try load again
      fail('The pose model did not load.', error);
    }
  })();

  return {
    stop() {
      stopped = true;
      release();
      host.replaceChildren();
    },
  };
}

window.overcisePose = { start };
