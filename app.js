require('dotenv').config();
const path = require('path');
const fs = require('fs')
const express = require('express');
const OS = require('os');
const bodyParser = require('body-parser');
const mongoose = require("mongoose");
const app = express();
const cors = require('cors')
const serverless = require('serverless-http')


app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '/')));
app.use(cors())
app.use('/images', express.static(path.join(__dirname, 'images')));

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
    user: process.env.MONGO_USERNAME,
    pass: process.env.MONGO_PASSWORD,
    useNewUrlParser: true,
    useUnifiedTopology: true
}, function(err) {
    if (err) {
        console.log("error!! " + err)
    } else {
      //  console.log("MongoDB Connection Successful")
    }
})

// Define Schema and Model
var Schema = mongoose.Schema;

var dataSchema = new Schema({
    name: String,
    id: Number,
    description: String,
    image: String,
    velocity: String,
    distance: String
});
var planetModel = mongoose.model('planets', dataSchema);


  // 🌍 Insert planet directly Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune

  planetModel.create({
      name: "Mercury",
      id: 1,
      description: "The closest planet to the Sun",
      image: "images/mercury.jpg",
      velocity: "47.87 km/s",
      distance: "57.91 million km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Mercury: " + err);
      } else {
          console.log("Mercury inserted successfully");
      }
  });

planetModel.create({
      name: "Venus",
      id: 2,
      description: "The second planet from the Sun",
      image: "images/venus.jpg",
      velocity: "35.02 km/s",
      distance: "108.2 million km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Venus: " + err);
      } else {
          console.log("Venus inserted successfully");
      }
  });

  planetModel.create({
      name: "Earth",
      id: 3,
      description: "Our home planet, mother Earth, the third planet from the Sun",
      image: "images/earth.jpg",
      velocity: "29.78 km/s",
      distance: "149.6 million km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Earth: " + err);
      } else {
          console.log("Earth inserted successfully");
      }
  });

  planetModel.create({
      name: "Mars",
      id: 4,
      description: "The fourth planet from the Sun, known as the Red Planet",
      image: "images/mars.jpg",
      velocity: "24.07 km/s",
      distance: "227.9 million km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Mars: " + err);
      } else {
          console.log("Mars inserted successfully");
      }
  });

  planetModel.create({
      name: "Jupiter",
      id: 5,
      description: "The fifth planet from the Sun and the largest in the Solar System",
      image: "images/jupiter.jpg",
      velocity: "13.07 km/s",
      distance: "778.5 million km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Jupiter: " + err);
      } else {
          console.log("Jupiter inserted successfully");
      }
  });

  planetModel.create({
      name: "Saturn",
      id: 6,
      description: "The sixth planet from the Sun, known for its prominent ring system",
      image: "images/saturn.jpg",
      velocity: "9.69 km/s",
      distance: "1.434 billion km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Saturn: " + err);
      } else {
          console.log("Saturn inserted successfully");
      }
  });

  planetModel.create({
      name: "Uranus",
      id: 7,
      description: "The seventh planet from the Sun, known for its blue color and unique tilt",
      image: "images/uranus.jpg",
      velocity: "6.81 km/s",
      distance: "2.871 billion km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Uranus: " + err);
      } else {
          console.log("Uranus inserted successfully");
      }
  });

  planetModel.create({
      name: "Neptune",
      id: 8,
      description: "The eighth planet from the Sun, known for its deep blue color",
      image: "images/neptune.jpg",
      velocity: "5.43 km/s",
      distance: "4.495 billion km"
  }, function(err) {
      if (err) {
          console.log("Error inserting Neptune: " + err);
      } else {
          console.log("Neptune inserted successfully");
      }
  });

// POST route to add a planet
app.post('/planet',   function(req, res) {
   // console.log("Received Planet ID " + req.body.id)
    planetModel.findOne({
        id: req.body.id
    }, function(err, planetData) {
        if (err) {
            alert("Ooops, We only have 9 planets and a sun. Select a number from 0 - 9")
            res.send("Error in Planet Data")
        } else {
            res.send(planetData);
        }
    })
})

// Get Home Page
app.get('/',   async (req, res) => {
    res.sendFile(path.join(__dirname, '/', 'index.html'));
});

// Get API Documentation
app.get('/api-docs', (req, res) => {
    fs.readFile('oas.json', 'utf8', (err, data) => {
      if (err) {
        console.error('Error reading file:', err);
        res.status(500).send('Error reading file');
      } else {
        res.json(JSON.parse(data));
      }
    });
  });

// Get OS Information
app.get('/os',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "os": OS.hostname(),
        "env": process.env.NODE_ENV
    });
})

// Health Check Routes
app.get('/live',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "live"
    });
})

// Readiness Check
app.get('/ready',   function(req, res) {
    res.setHeader('Content-Type', 'application/json');
    res.send({
        "status": "ready"
    });
})

// Start server

app.listen(3000, () => { console.log("Server successfully running on port - " +3000); })
module.exports = app;

//module.exports.handler = serverless(app)
