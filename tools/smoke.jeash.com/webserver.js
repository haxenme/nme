var express = require('express')
  , http = require('http');

var app = express();

//app.get('*.png', function (request, response) {
//	response.contentType('image/png');
//});

app.configure(function(){
	app.use(express.logger());
  app.use(express.static(__dirname));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
});

app.get('*', function(request, response){
	response.status = 200;
	response.send(request.query);
});

app.post('*', function(request, response){
	response.status = 200;
	response.send(request.body);
});

http.createServer(app).listen(3001);

