// pull in desired CSS/SASS files
require("./styles/main.scss");

// inject bundled Elm app into div#main
var Elm = require("../elm/Main");
var elmApp = Elm.Main.embed(document.getElementById("main"));

elmApp.ports.sendToken.subscribe(token => {
  console.log({ token });
  localStorage.setItem("token", token);
});

navigator.getUserMedia =
  navigator.getUserMedia ||
  navigator.webkitGetUserMedia ||
  navigator.mozGetUserMedia;

const init = () => {
  const token = localStorage.getItem("token");
  if (token) {
    elmApp.ports.receiveToken.send(token);
  }
};

const capture = (video, canvas) => {
  const ctx = canvas.getContext("2d");
  ctx.drawImage(video, 0, 0);
  var dataURL = canvas.toDataURL("image/png");
  return dataURL;
};

const startVideo = video =>
  new Promise((resolve, reject) => {
    if (navigator.getUserMedia) {
      navigator.getUserMedia(
        { video: { facingMode: "environment" } },
        stream => {
          video.srcObject = stream;
          video.onloadedmetadata = () => {
            video.play();
          };
          resolve(stream);
        },
        reject
      );
    } else {
      reject("getUserMedia not supported");
    }
  });

const stopVideo = (stream, video) => {
  video.pause();
  stream.stop();
};

elmApp.ports.sendStartCapture.subscribe(event => {
  requestAnimationFrame(() => {
    var videoEl = document.querySelector("#video");
    var canvasEl = document.querySelector("#canvas");
    var captureBtn = document.querySelector("#capture");
    startVideo(videoEl).then(stream => {
      captureBtn.addEventListener(
        "click",
        () => {
          const image = capture(videoEl, canvasEl);
          elmApp.ports.receiveStartCapture.send(image);
          stop(stream, video);
        },
        false
      );
    });
  });
});

init();
