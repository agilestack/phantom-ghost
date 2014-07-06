ghost = require './phantom-node-promise'
scrape = ghost [
  ->
    els = document.querySelectorAll 'a.post_title'
    result = []
    for i in [0..els.length-1]
      result.push
        title:
          header: els[i].innerText
          link: els[i].href
    
    items:
      result
]

scrape('http://habrahabr.ru/').then (result) ->
  items = result.data[0].features.items
  for i in [0..items.length-1]
    console.log "#{items[i].title.header} - #{items[i].title.link}"