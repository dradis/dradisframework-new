document.addEventListener "turbo:load", ->

  if $('body.boards.index').length

    # when creating a new board and we select a template:
    # - choose the "from template" radio
    # - if board name is empty, populate it with the selected option
    $('[data-behavior~=new-board-template]').on 'change', ->
      $('[data-behavior~=use-template]').prop('checked', true)

      selected_option = $('[data-behavior~=new-board-template] option:selected').text()
      if !$('[data-behavior~=new-board-name]').val()
        # empty board name, use the selected one by default
        $('[data-behavior~=new-board-name]').val(selected_option)
      else if $('[data-behavior~=new-board-template] option').filter(-> this.text == $('[data-behavior~=new-board-name]').val()).length
        # not empty board name, but it was one of the templates, use the selected one
        $('[data-behavior~=new-board-name]').val(selected_option)

    # when we clik the "From template" radio, also populate the name input with
    # the template name
    $('[data-behavior~=use-template]').on 'click', ->
      selected_option = $('[data-behavior~=new-board-template] option:selected').text()
      $('[data-behavior~=new-board-name]').val(selected_option)
