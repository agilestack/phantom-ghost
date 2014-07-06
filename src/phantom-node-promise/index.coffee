Q = require 'q'
lo = require 'lodash'

Phantom = require 'phantom'

colors = require 'colors'
colors.setTheme
  silly: 'rainbow'
  input: 'grey'
  verbose: 'cyan'
  prompt: 'grey'
  info: 'green'
  data: 'grey'
  help: 'cyan'
  warn: 'yellow'
  debug: 'blue'
  error: 'red'


createPhantom = ->
  console.log "Starting PhantomJS instance".info
  d = Q.defer()
  lo.tap d.promise, ->
    Phantom.create (ph) ->
      console.log "PhantomJS process started".info
      if ph then d.resolve ph else d.reject(new Error("Unable to create PhantomJS instance"))

createPage = (F) ->
  d = Q.defer()
  lo.tap d.promise ->
    if F
      F.createPage (page) ->
        d.resolve page
    else
      phantom().then (ph) ->
        ph.createPage (page) ->
          d.resolve page


$titleExtractor = -> 
  page:
    title: document.title
$metaExtractor = ->
  metaInfo = []
  metaElements = document.getElementsByTagName 'meta'
  for element in metaElements
    metaInfo.push
      name: element.getAttribute 'name'
      content: element.getAttribute 'content'
  
  page:
    meta: metaInfo

$commonExtractors = [
  $titleExtractor
  $metaExtractor
]


ghost = (providedExtractors, providedCrawlers, providedPostProcessors, providedOptions) ->
  defaultOptions =
    breakOnPageStatus: false
    debug: false
    exploredURLs: undefined
    urlsToExplore: undefined

  options = lo.defaults defaultOptions, providedOptions
  extractors = lo.clone $commonExtractors
  extractors = extractors.concat(lo.compact(providedExtractors)) if providedExtractors?

  postProcessors = providedPostProcessors or []
  crawlers = providedCrawlers or []

  debug = options.debug

  cleanUrl = (url) ->
    v = url.replace 'http://', ''
    v = v.replace 'https://', ''
    v = v.replace '/', '-'
    v = v.replace '.', '-'
    return v

  applyExtractor = (page, extractors, reduce, done) ->
    currentExtractor = extractors.pop()
    unless currentExtractor?
      done()
      return
    page.evaluate currentExtractor, (result) ->
      reduce result
      applyExtractor page, extractors, reduce, done


  (url) ->
    deferred = Q.defer()

    lo.tap deferred.promise, ->
      results =
        exploredURLs: options.exploredURLs or []
        urlsToExplore: options.urlsToExplore or [url]
        data: []

      phantomPage = undefined
      ph = undefined

      pageRunner = (page) =>
        phantomPage = page

        currentUrl = undefined
        while (currentUrl = results.urlsToExplore.pop())
          if results.exploredURLs.indexOf(currentUrl) >= 0
            console.log "Skipped #{currentUrl}. It is visited already.".debug
            continue
          else
            break
        unless currentUrl?
          ph.exit()
          console.log "Exiting PhantomJS instance. No URLs to visit remain.".info
          deferred.resolve results
          return

        nextPage = ->
          results.exploredURLs.push currentUrl
          pageRunner page

        console.log ('Processing URL: ' + currentUrl).info

        page.open currentUrl, (status) ->
          unless status == 'success'
            if options.breakOnPageStatus
              deferred.reject new Error "Unable to open page URL: #{currentUrl}"
            else
              console.log "Unable to open the following URL: #{currentUrl}. The error was skipped because `breakOnPageStatus' is set to false.".debug
              nextPage()
            return
            
          page.render "#{cleanUrl(currentUrl)}.shot.png" if debug

          container =
            uri: currentUrl
            features: {}

          applyExtractor page, lo.clone(extractors), ((result) -> container.features = lo.merge container.features, result), ->
            while (postProcessor = postProcessors.pop())
              container = lo.merge container postProcessor container

            results.data.push container

            applyExtractor page, lo.clone(crawlers), ((result) -> results.urlsToExplore = results.urlsToExplore.concat result), ->
              console.log ('... well done.').info                
              nextPage()

      createPhantom().then((phantomInstance) ->
        ph = phantomInstance
        if phantomPage then pageRunner(phantomPage) else ph.createPage pageRunner
      ).catch(-> console.log "Unable to start PhantomJS instance".error)


module.exports = ghost