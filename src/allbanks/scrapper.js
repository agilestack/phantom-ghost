var phantom = require('phantom');

function extractor() {
	function _(evalString){
		try {
			return eval(evalString);
		} catch (err) {
			return '# Error: ' + err;
		}
	};

	var features = [];

	var banksBlocks = document.querySelectorAll('table.bankBlock');
	for (var i = 0; i < banksBlocks.length; i++) {
		var bank = banksBlocks[i];
		features.push({
			title: _("bank.querySelector('h3').querySelector('a').innerText"),
			URI: _("bank.querySelector('h3').querySelector('a').href"),
			siteURL: _("bank.querySelectorAll('div[title]>a')[0].href"),
			nco: _("bank.querySelector('h3').querySelector('span.nco') !== null"),
			country: _("bank.querySelectorAll('h3>a')[1].innerText"),
			license: _("bank.querySelector('.license').innerText"),
			address: _("bank.querySelectorAll('div:not(.license):not([title])')[0].innerText"),
			phone: _("bank.querySelectorAll('div>nobr')[0].innerText")
		});
	}

	return features;
}

function crawler() {
	try {
		return [document.querySelector('a[title=следующая]').href];
	} catch (e) {
		return [];
	}
}

function postProcessor(descriptor) {
	var updated = {};
	for (var k in descriptor) {
		updated[k] = descriptor[k];
	}

	for (var k in updated['feature']) {
		
		if ((updated['feature'][k]).toString().indexOf('# Error')>=0) {
			updated['feature'][k] = undefined;
		} else {
			updated['feature'][k] = updated['feature'][k].toString();
		}
	}

	if (updated['feature']['country'] != 'Россия') {
		return undefined;
	}

	if (updated['feature']['phone'] !== undefined) {
		updated['feature']['phone'] = updated['feature']['phone'].replace(/\D+/gi, '');
		if (updated['feature']['phone'][0] != '8' && updated['feature']['phone'][0] != '7') {
			updated['feature']['phone'] = '+7' + updated['feature']['phone'];
		}
	} 

	return updated;
}

function $commonFeaturesExtractor(page) {
	
	return function () {
		var commonFeature = {
			'url': document.location.href,
			'title': document.title,
			'timestamp': Date.now(),
		};
		return commonFeature;
	};
}


function scrap(options, startPage, featuresExtractor, crawlingExtractor, postProcessor, done, fail) {
	phantom.create (function(ph){
		var urlsToParse = [startPage];
		var features = [];
		var postProcessed = function (f) { return f; };
		if (postProcessor) { postProcessed = postProcessor; }



		function next() {
			ph.createPage(function(page){
				page.viewportSize = {
					width: 1280,
					height: 960
				};

				var url = urlsToParse.pop();

				if (!url) { done(features); return;}

				page.open(url, function(status){
					// if (status != 'success') {
					// 	console.log('Fail on page: ', url);
					// 	console.log('Queue content: ', urlsToParse);
					// 	fail();
					// 	return;
					// }

					page.evaluate($commonFeaturesExtractor(page), function(_commonFeatures){
						var commonFeatures = _commonFeatures;
						page.evaluate(featuresExtractor, function(_pageFeatures){
							var pageFeatures = _pageFeatures;
							page.evaluate(crawlingExtractor, function(_nextUrls){
								var nextUrls = _nextUrls;
								for (var i = 0; i < pageFeatures.length; i++) {
									featureDescriptor = {};
									for (var k in commonFeatures) {
										featureDescriptor[k] = commonFeatures[k];
									}
									featureDescriptor['feature'] = pageFeatures[i];
									var clean = postProcessed(featureDescriptor);
									if (clean) features.push(clean);
								}

								for (var i = 0; i < nextUrls.length; i++) {
									urlsToParse.push(nextUrls[i]);
								}

								console.log('Next pages: ', nextUrls);
								console.log('Found features: ', pageFeatures.length);
								if (pageFeatures.length > 0) console.log('Sample feature: ', JSON.stringify(features[features.length-1]));
						
								console.log('Ended page: ', url);
								next();
								
								
								
							})})});

				});
			})
		}

});
}


function Scrapper(options, done, fail, startUrl){
	scrap({}, startUrl || 'http://www.allbanks.ru/banks/',
		extractor, crawler, postProcessor, done, fail);
}

exports.scrapper = Scrapper;