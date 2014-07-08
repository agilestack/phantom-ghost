# todo:
# 1. Как быть со страницами, для которых нужно применять разные экстракторы?
# 2. Что делать если хочется просто получить список ссылок? <использовать также экстракторы без краулеров>
# 3. Как сохранить простоту структуры скрапера для случая с несколькими страницами?
# 4. Generic Extractor 

genericExtractor ->
	


# ghost
#   pages: ["index", "category"]
#   extractors:
#   	index: [
#   		->
#   		->
#   		->
#   	]
#   	category: [
#   		->
#   	]
#   crawlers:
#   	index: ->
#   	category: ->
#   postProcessors:
#   	index:

# url = ['URL', 'class']

ghost = require './phantom-node-promise'
scrape = ghost [
	#Extractors
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