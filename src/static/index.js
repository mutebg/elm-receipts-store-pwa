// pull in desired CSS/SASS files
require("./styles/main.scss");

// inject bundled Elm app into div#main
var Elm = require("../elm/Main");
var elmApp = Elm.Main.embed(document.getElementById("main"));

elmApp.ports.sendToken.subscribe(credetials => {
  localStorage.setItem("token", credetials.token);
  localStorage.setItem("refreshToken", credetials.refreshToken);
});

navigator.getUserMedia =
  navigator.getUserMedia ||
  navigator.webkitGetUserMedia ||
  navigator.mozGetUserMedia;

const init = () => {
  const refreshToken = localStorage.getItem("refreshToken");
  if (refreshToken) {
    fetch(
      "https://securetoken.googleapis.com/v1/token?key=AIzaSyAcFNMw-GikdJ019_Uvg8gVGcoR1TRVJfY",
      {
        method: "POST",
        headers: {
          Accept: "application/json, text/plain, */*",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          grant_type: "refresh_token",
          refresh_token: refreshToken
        })
      }
    )
      .then(response => response.json())
      .then(response => {
        localStorage.setItem("token", response.id_token);
        localStorage.setItem("refreshToken", response.refresh_token);

        elmApp.ports.receiveToken.send({
          token: response.id_token,
          refreshToken: response.refresh_token
        });
      });
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
        {
          video: {
            facingMode: "environment",
            width: window.screen.width,
            height: window.screen.height
          }
        },
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
  return fetch(
    "https://us-central1-elm-receipts.cloudfunctions.net/api/upload/",
    {
      method: "POST",
      headers: headers,
      body: formData
    }
  );
};

let videoGlobal;
let canvasGlobal;
let streamGlobal;

elmApp.ports.sendStopCapture.subscribe(event => {
  stopVideo(streamGlobal, videoGlobal);
});

elmApp.ports.sendTakePicture.subscribe(event => {
  capture(videoGlobal, canvasGlobal).then(blobImage => {
    saveImage(blobImage).then(response => response.json()).then(json => {
      console.log(json);
      elmApp.ports.receiveStartCapture.send({
        key: "",
        amount: json.amount,
        typeId: 999,
        date: new Date().toString(),
        description: "",
        invoice: json.fileUrl
      });
      stopVideo(streamGlobal, videoGlobal);
    });
  });
});

elmApp.ports.sendStartCapture.subscribe(event => {
  requestAnimationFrame(() => {
    videoGlobal = document.querySelector("#video");
    canvasGlobal = document.querySelector("#canvas");
    canvasGlobal.width = window.screen.width;
    canvasGlobal.height = window.screen.height;
    startVideo(videoGlobal).then(stream => {
      streamGlobal = stream;
    });
  });
});

init();

if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register("sw.js")
    .then(registration => {
      console.log("SW registerd");
    })
    .catch(error => {
      console.log("SW fail to register", error);
    });
}
