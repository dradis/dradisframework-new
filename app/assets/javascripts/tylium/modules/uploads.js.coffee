document.addEventListener "turbo:load", ->
  if $('body.upload').length
    # Enable Ajax file uploads via 3rd party plugin
    $bar = $('.progress-bar');
    $percent = $('.percent');
    $status = $('#status');
    $('form#new_upload').ajaxForm({
      dataType: 'script'
      beforeSend: ->
          $status.empty();
          percentVal = '0%';
          $bar.width(percentVal)
          $bar.addClass('bg-primary')
          $percent.html(percentVal);
      uploadProgress: (event, position, total, percentComplete)->
          percentVal = percentComplete + '%';
          $bar.width(percentVal)
          $percent.html(percentVal);
          $percent.css('color', '#fff;')
      success: ->
          percentVal = '100%';
          $bar.width(percentVal)
          $bar.removeClass('bg-primary').addClass('bg-success')
          $percent.html(percentVal);
    });

    $(':file').change ->
      ConsoleUpdater.jobId = ConsoleUpdater.jobId + 1
      fileName = this.value.split('\\').pop()
      $('#console').empty()
      $('#filename').text(fileName)
      $('#spinner').show()
      $('#result').data('id', ConsoleUpdater.jobId)
      $('#result').show()
      $('#item_id').val(ConsoleUpdater.jobId)
      $('[data-behavior~=file-label]').text(fileName)

      $(this).closest('form').submit()
      # Can't use this, because Rails UJS doesn't kick in (missing CSRF)
      # $(this).closest('form').trigger('submit.rails');

    $uploader = $('#uploader')
    $uploader.change ->
      uploader = $(this).val()
      new RTPValidation({ rtpId: $('[data-behavior~=rtp-validation]').data('rtp-id'), uploader: uploader })
