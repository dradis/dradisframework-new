document.addEventListener "turbo:load", ->

  # Nodes#show shortcuts
  if $('body.nodes').length
    # Save current note / issue
    $(document).bind 'keydown', 'Meta+s', ->
      alert 'TODO: implement save'
      false

    $(document).bind 'keydown', 'Meta+o', ->
      new bootstrap.Dropdown($(".dropdown-toggle[data-name='notes']")).show();
      false

    $(document).bind 'keydown', 'Meta+e', ->
      new bootstrap.Dropdown($(".dropdown-toggle[data-name='evidence']")).show();
      false
