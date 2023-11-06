class SortableBoards
  generatePlaceholder: (className) ->
    return (currentItem) ->
      styleAttr =
        "style='width: " + currentItem.width() +
        "px; height: " + currentItem.height() + "px;'"
      return $("<li class='sortable-placeholder " + className + "' " + styleAttr + "></li>")[0]

  updateListCount: (sourceId, destId) ->
    oldCounter = $(".list[data-list-id='" + sourceId + "'] .js-list-count")
    newCounter = $(".list[data-list-id='" + destId + "'] .js-list-count")

    oldCounter.text(parseInt(oldCounter.text()) - 1)
    newCounter.text(parseInt(newCounter.text()) + 1)

  updatePosition: (url, params) ->
    $('.js-sortable-lists').sortable('option', 'disabled', true)
    $('.js-sortable-cards').sortable('option', 'disabled', true)

    $.ajax
      url: url
      data: params
      dataType: 'json'
      type: 'post'
      success: (data, status, xhr) ->
        if data.is_card
          $cardLink = $(".card[data-card-id='#{data.id}'] a")
          $cardLink.attr('href', data.link)
          $cardLink.closest('.card').data('move-url', data.moveLink)
        return
      complete: (xhr, status) ->
        $('.js-sortable-lists').sortable('option', 'disabled', false)
        $('.js-sortable-cards').sortable('option', 'disabled', false)

    return


document.addEventListener "turbo:load", ->

  if $('body.boards.show').length
    # ------------------------------------------------------------- List modals

    # Instantiate reusable variables
    item = newListId = oldListId = prevIndex = null

    # ------------------------------------------------------------ /List modals

    # ----------------------------------------------------------------- Sorting
    sortableBoard = new SortableBoards()

    $(document).on 'sortable:init', ->
      $('.js-sortable-cards').sortable
        connectWith: '.js-sortable-cards'
        placeholder:
          element: sortableBoard.generatePlaceholder('card')
          update: (container, p) -> return

        start: (event, ui) ->
          newListId = oldListId = $(ui.item).closest('.list').data('list-id')
          prevIndex = ui.item.index()
        change: (event, ui) ->
          if (ui.sender)
            newListId = $(ui.placeholder).closest('.list').data('list-id')
        stop: (event, ui) ->
          currentCard = $(ui.item)

          sortableBoard.updateListCount(oldListId, newListId) if oldListId != newListId

          # Send out db request only if the card is moved to a new position
          if oldListId != newListId || prevIndex != ui.item.index()
            boardId = currentCard.closest('.board').data('board-id')
            cardId = currentCard.data('card-id')

            params =
              prev_id: currentCard.prev().data('card-id')
              next_id: currentCard.next().data('card-id')
              new_list_id: newListId

            sortableBoard.updatePosition(currentCard.data('move-url'), params)


      $('.js-sortable-lists').sortable
        connectWith: '.js-sortable-lists'
        items: '.list:not(.list-new)'
        tolerance: 'pointer'
        update: (event, ui) ->
          currentList = $(ui.item)

          boardId = currentList.closest('.board').data('board-id')
          listId = currentList.data('list-id')
          params =
            prev_id: currentList.prevAll('.list:first').data('list-id')
            next_id: currentList.nextAll('.list:first').data('list-id')

          sortableBoard.updatePosition(currentList.data('move-url'), params)

        placeholder:
          element: sortableBoard.generatePlaceholder('list')
          update: (container, p) -> return

    $(document).trigger 'sortable:init'

    return
    # ---------------------------------------------------------------- /Sorting
