document.addEventListener "turbo:load", ->
  if $('body.configurations').length

    $('tbody tr.gemified td.value').on('blur', 'input', ->
      $(this).removeClass 'editing'

    ).on('change', 'input', ->
      names                 = $(this).attr('name').split('_settings_')
      plugin_name           = names[0]
      setting_name          = names[1]
      post_path             = $(this).parents('form').attr('action')
      full_post_path        = post_path + '/' + plugin_name
      setting               = {}
      setting[setting_name] = $(this).val()

      ajax_opts =
        context: $(this)
        data: setting: setting
        dataType: 'json'
        type: 'post'
        complete: ->
          $(this).removeClass 'saving'
        error: (xhr, status, error) ->
          $(this).addClass 'failed'
        success: (data, status, xhr) ->
          $(this).addClass 'saved'
          setting_status = if data['setting_is_default'] then 'default' else 'user set'
          $(this).parents('td').siblings('td.status').text setting_status

      $.extend true, ajax_opts,
        data: '_method': 'put'
        url: full_post_path

      $(this).addClass 'saving'
      $.ajax ajax_opts

    ).on 'keydown', 'input', (e) ->
      $(this).addClass('editing').removeClass 'saved', 'failed'
