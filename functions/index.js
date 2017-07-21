const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

const app = express();

admin.initializeApp(functions.config().firebase);

// Express middleware that validates Firebase ID Tokens passed in the Authorization HTTP header.
// The Firebase ID token needs to be passed as a Bearer token in the Authorization HTTP header like this:
// `Authorization: Bearer <Firebase ID Token>`.
// when decoded successfully, the ID Token content will be added as `req.user`.
const authenticate = (req, res, next) => {
  if (
    !req.headers.authorization ||
    !req.headers.authorization.startsWith("Bearer ")
  ) {
    res.status(403).send("Unauthorized");
    return;
  }
  const idToken = req.headers.authorization.split("Bearer ")[1];
  admin
    .auth()
    .verifyIdToken(idToken)
    .then(decodedIdToken => {
      req.user = decodedIdToken;
      next();
    })
    .catch(error => {
      res.status(403).send("Unauthorized");
    });
};

app.use(cors());
app.use(authenticate);

// POST /api/receipts
// Create a new receipts
app.post("/receipts", (req, res) => {
  const date = req.body.date;
  const amount = req.body.amount;
  const invoice = req.body.invoice;
  const description = req.body.description;
  const typeId = req.body.typeId;
  const data = { date, amount, invoice, description, typeId };

  admin
    .database()
    .ref(`/users/${req.user.uid}/receipts`)
    .push(data)
    .then(snapshot => {
      return snapshot.ref.once("value");
    })
    .then(snapshot => {
      const val = Object.assign({}, { key: snapshot.key }, snapshot.val());
      res.status(201).json(val);
    })
    .catch(error => {
      console.log("Error detecting sentiment or saving receipt", error.message);
      res.sendStatus(500);
    });
});

// Get all receipts
app.get("/receipts", (req, res) => {
  let query = admin.database().ref(`/users/${req.user.uid}/receipts`);
  query
    .once("value")
    .then(snapshot => {
      var receipts = [];
      snapshot.forEach(childSnapshot => {
        receipts.push(
          Object.assign({}, { key: childSnapshot.key }, childSnapshot.val())
        );
      });

      return res.status(200).json(receipts);
    })
    .catch(error => {
      console.log("Error getting receipts", error.message);
      res.sendStatus(500);
    });
});

// Get details about a receipts
app.get("/receipts/:receiptsId", (req, res) => {
  const receiptsId = req.params.receiptsId;
  admin
    .database()
    .ref(`/users/${req.user.uid}/receipts/${receiptsId}`)
    .once("value")
    .then(snapshot => {
      if (snapshot.val() !== null) {
        // Cache details in the browser for 5 minutes
        res.set("Cache-Control", "private, max-age=300");
        res
          .status(200)
          .json(Object.assign({}, { key: snapshot.key }, snapshot.val()));
      } else {
        res.status(404).json({
          errorCode: 404,
          errorMessage: `receipt '${receiptsId}' not found`
        });
      }
    })
    .catch(error => {
      console.log("Error getting receipt", receiptsId, error.message);
      res.sendStatus(500);
    });
});

// Delete recept
app.delete("/receipts/:receiptsId", (req, res) => {
  const receiptsId = req.params.receiptsId;
  admin
    .database()
    .ref(`/users/${req.user.uid}/receipts/${receiptsId}`)
    .remove()
    .then(() => {
      return res.status(200).json({ status: true });
    })
    .catch(error => {
      console.log("Error deleting receipt", receiptsId, error.message);
      res.sendStatus(500);
    });
});

// Upload receipt image
app.post("/upload", (req, res) => {
  return res.status(200).json({ done: true });
});

// Expose the API as a function
exports.api = functions.https.onRequest(app);
