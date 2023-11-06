App.cable.subscriptions.create 'NotificationsChannel',
  connected: ->
    console.log('Subscribed to NotificationsChannel.')
    @perform('check_unread', {})
    $(document).on 'turbo:load.notifications', =>
      @perform('check_unread', {})

  rejected: ->
    console.log('Error subscribing to NotificationsChannel.')
    $(document).off('.notifications')

  received: (data)->
    favicon = $('[data-behavior~=favicon]')

    if data == 'all_read'
      $('[data-behavior~=notifications-dot]').addClass('d-none')
      favicon.attr('href', favicon.data('read'))
    else
      $('[data-behavior~=notifications-dot]').removeClass('d-none')
      favicon.attr('href', favicon.data('unread'))
