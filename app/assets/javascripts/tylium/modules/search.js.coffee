class SearchWordHighlight
  highlight: (element, term) ->
    src_str = element.html()
    term    = term.replace(/(\s+)/, '(<[^>]+>)*$1(<[^>]+>)*')
    pattern = new RegExp('(' + term + ')', 'gi')
    src_str = src_str.replace(pattern, '<mark>$1</mark>')
    src_str = src_str.replace(/(<mark>[^<>]*)((<[^>]+>)+)([^<>]*<\/mark>)/, '$1</mark>$2<mark>$4')
    element.html src_str


document.addEventListener "turbo:load", ->
  if $('body.search.index').length
    highlighter = new SearchWordHighlight
    query = $(".form-search #q").val()
    $('#tbl-search .search-matches').each ->
      highlighter.highlight($(this), query)
