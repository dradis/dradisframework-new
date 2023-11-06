document.addEventListener "turbo:load", ->

  if $('.js-diff-body').length
    delRegex = /\[31m([\s\S]*?)\[0m/g
    insRegex = /\[32m([\s\S]*?)\[0m/g

    diffText = $('.js-diff-body').html()

    newText =
      diffText.
      replace(delRegex, '<del class="differ">$1</del>').
      replace(insRegex, '<ins class="differ">$1</ins>')

    $('.js-diff-body').html(newText)
