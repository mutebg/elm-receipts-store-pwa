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

const capture = (video, canvas) =>
  new Promise((resolve, reject) => {
    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0);
    canvas.toBlob(blob => {
      resolve(blob);
    });
  });

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
  stream.getVideoTracks()[0].stop();
};

const saveImage = blobImage => {
  const formData = new FormData();
  formData.append("file", blobImage);

  const headers = new Headers();
  //headers.append("Content-Type", "text/plain");
  //headers.append("Content-Length", content.length.toString());
  headers.append("Authorization", "Bearer " + localStorage.getItem("token"));
  return fetch("http://localhost:5002/elm-receipts/us-central1/api/upload/", {
    method: "POST",
    headers: headers,
    body: formData
  });
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
          capture(videoEl, canvasEl).then(blobImage => {
            saveImage(blobImage)
              .then(response => response.json())
              .then(json => {
                console.log(json);
                elmApp.ports.receiveStartCapture.send({
                  key: "",
                  amount: json.amount,
                  typeId: 999,
                  date: new Date().toString(),
                  description: "",
                  invoice: json.fileUrl
                });
                stopVideo(stream, video);
              });
          });
        },
        false
      );
    });
  });
});

init();
