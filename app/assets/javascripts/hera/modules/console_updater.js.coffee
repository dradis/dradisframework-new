@ConsoleUpdater =
  jobId: 0
  parsing: false

  updateConsole: ->
    unless ConsoleUpdater.parsing
      # danger will robinson, this is only valid for Export workers
      if $('#download').length
        $('#download').attr('disabled', false).text('Download');

      return

    after = 0
    if $('.log').length
      after = $('#console p:last-child').data('id')

    url = $('#result').data('url')

    $.get(
      url,
      {item_id: ConsoleUpdater.jobId, after: after},
      null,
      'script'
    )
