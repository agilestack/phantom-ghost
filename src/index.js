var lo = require('lodash');
var allbanks = require('./allbanks/scrapper.js').scrapper;

allbanks({}, function(features){
	console.log(features.length);
}, function(){
	console.log('fail');
	return;
});