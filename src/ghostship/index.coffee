_ = require 'lodash'

phantom = require 'phantom'

_info = -> console.info.apply undefined, arguments


scrapThePage = (URL, featuresExtractors, postProcessors, phantomInstance, done, fail) ->

  runScrape = (ph) ->
    ph.createPage (page) ->
      page.open URL, (status) ->
        if status != 'success'
          fail(page, status)

  if phantomInstance
    runScrape phantomInstance
  else
    phantom.create (ph) ->
      runScrape ph
