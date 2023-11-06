class @SelectTagDropdown
  constructor: (@$target) ->
    @init()

  init: ->
    $('#issue_tag_list').val(@$target.data('tag'))
    $span = $("#issues_editor .dropdown-toggle span.tag")
    $span.css("color", @$target.css("color"))
    $span.html(@$target.html())

document.addEventListener "turbo:load", ->
  $('#issues_editor .js-taglink').click (e) ->
    $target = $(e.target)
    new SelectTagDropdown($target)
    $('#issue_tag_list').trigger('textchange')
