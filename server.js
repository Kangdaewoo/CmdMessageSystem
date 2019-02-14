var express = require('express');
var app = express();
app.use(express.static(__dirname + '/'));

var bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: true}));
app.use(bodyParser.json());

var morgan = require('morgan');
app.use(morgan('dev'));

var config = require('./config');
app.set('superSecret', config.secret);


var users = {};

// For debugging
app.get('/users', function(req, res) {
    res.json({users: users});
});

app.get('/', function(req, res) {
    res.json({message: 'Hi, what is your name?', success: "true"});
});



app.post('/name', function(req, res) {
    if (req.body.name in users) {
        return res.json({message: 'That name is already in use', success: "false"});
    }

    users[req.body.name] = [];
    res.json({message: `Welcome, ${req.body.name}`, success: "true"});
});

app.use('/:name', function(req, res, next) {
    if (!(req.params.name in users)) {
        return res.json({message: "We don't know you", success: "false"});
    }
    next();
});

app.get('/:name/message', function(req, res) {
    const temp = users[req.params.name].slice(0);
    users[req.params.name] = [];
    res.json({message: 'Here are unread messages', messages: temp, success: "true"});
});

app.post('/:name/message', function(req, res) {
    if (req.body.to === undefined) {
        res.json({message: 'Who are you talking to?', success: "false"});
    } else if (req.body.to === req.params.name) {
        res.json({message: "Don't talk to yourself", success: "false"});
    } else if (req.body.to in users) {
        users[req.body.to].push({from: req.params.name, message: req.body.message});
        res.json({message: "Message sent successfully", success: "true"});
    } else {
        res.json({message: "User doesn't exist", success: "false"});
    }
});

app.get('/:name/logout', function(req, res) {
    delete users[req.params.name];
    res.json({message: 'Goodbye', success: "true"});
});


const port = 8888 || process.env.PORT;
var server = app.listen(port, function() {
    console.log('Running on localhost:%s', server.address().port);
});