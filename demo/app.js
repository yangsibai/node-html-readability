var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var readability = require("../lib/index");
var request = require("request");

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(favicon());
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', function (req, res) {
	url = req.query.url
	if (url) {
		request(decodeURIComponent(url), function (err, response, body) {
			if (err) {
				res.send(err);
			}
			else {
				read = new readability({
					url: url,
					debug: true,
					content: body.toString()
				});
				article = read.run();
				res.render("article", article);
			}
		})
	}
	else {
		demoSites = [
			"http://weblogs.asp.net/bsimser/day-to-day-with-subversion",
			"http://jianshu.io/p/77c949565112",
			"http://sports.sina.com.cn/nba/2014-08-24/03547305054.shtml",
			"https://medium.com/code-adventures/farewell-node-js-4ba9e7f3e52b"
		];
		res.render("index", {
			title: "readability demo",
			demoSites: demoSites
		});
	}
});

/// catch 404 and forward to error handler
app.use(function (req, res, next) {
	var err = new Error('Not Found');
	err.status = 404;
	next(err);
});

/// error handlers

// development error handler
// will print stacktrace
app.use(function (err, req, res, next) {
	res.status(err.status || 500);
	res.render('error', {
		message: err.message,
		error: err
	});
});

var server = app.listen(3000, function () {
	console.log('Express server listening on port ' + server.address().port);
});