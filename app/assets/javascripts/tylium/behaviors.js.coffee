# behaviors.js
#
# In this file we bind general-purpose jQuery plugins with the corresponding
# elements in the page in an unobtrusive way.
#
# The current list of plugins:
#   * jQuery.Textile     - handles the note editor (/vendor/)

document.addEventListener "turbo:load", ->

  # --------------------------------------------------- Standard jQuery plugins

  # Initialize clipboard.js:
  clipboard = new Clipboard('.js-attachment-url-copy')

  clipboard.on 'success', (e) ->
    $btn = $(e.trigger)
    e.clearSelection()
    $btn.tooltip
      placement: 'bottom'
      title:     'Copied attachment URL to clipboard!',
      trigger:   'manual'
    $btn.tooltip('show')


  clipboard.on 'error', (e) ->
    actionKey = if e.action == 'cut' then 'X' else 'C'
    if /Mac/i.test(navigator.userAgent)
      actionMsg = 'Press ⌘-' + actionKey + ' to '+ e.action
    else
      actionMsg = 'Press Ctrl-' + actionKey + ' to ' + e.action

    $btn = $(e.trigger)

    $btn.tooltip
      placement: 'bottom'
      title:     actionMsg
      trigger:   'manual'
    $btn.tooltip('show')


  $(".attachments-box").on "mouseleave", ".js-attachment-url-copy", ->
    $this = $(this)
    $this.tooltip('hide')


  # -------------------------------------------------------- Our jQuery plugins

  # Activate jQuery.breadCrumbs
  $('.breadcrumb').breadcrumbs
    tree: $('.main-sidebar .tree-navigation')

  # Activate jQuery.treeNav
  $('.tree-navigation').treeNav()

  # Activate jQuery.treeModal
  $('.modal-node-selection-form').treeModal()

  # ------------------------------------------------------- Bootstrap behaviors

  # Focus first input on modal window display.

  $('.modal').on 'shown.bs.modal', ->
    $(this).find('input:text:visible:first').focus()

  $('body').on 'click', '.js-try-pro', ->
    $this   = $(this)
    term    = $this.data('term')
    $modal  = $('#try-pro')
    $iframe = $('#try-pro iframe')
    url     = $iframe.data('url')

    if $this.data('url')
      url = $this.data('url')

      title = switch term
        when 'boards' then '<span>[Dradis Pro feature]</span> Advanced boards and task assignment'
        when 'contact-support' then '<span>[Dradis Pro feature]</span> Dedicated Support team'
        when 'issuelib' then '<span>[Dradis Pro feature]</span> Integrated library of vulnerability descriptions'
        when 'gateway' then '<span>[Dradis Pro feature]</span> A Dynamic and Interactive Assessment Results Portal'
        when 'projects' then '<span>[Dradis Pro feature]</span> Work with multiple projects'
        when 'remediation' then '<span>[Dradis Pro feature]</span> Integrated remediation tracker'
        when 'word-reports' then '<span>[Dradis Pro feature]</span> Custom Word reports'
        when 'excel-reports' then '<span>[Dradis Pro feature]</span> Custom Excel reports'
        when 'node-boards' then '<span>[Dradis Pro feature]</span> Node-level methodologies'
        when 'training-course' then 'Dradis Training Course'
        when 'try-pro' then 'Upgrade to Dradis Pro'

      $modal.find('[data-behavior~=modal-title]').html(title)
    else
      $modal.find('[data-behavior~=modal-title]').text('Dradis Framework editions')

    url = url + '?utm_source=ce&utm_medium=app&utm_campaign=try-pro&utm_term=' + term

    $iframe.attr('src', url)
    new bootstrap.Modal('#try-pro').show()

  # If project id is changed in project path
  if !(/^\/projects\/1(\/|$)/.test(window.location.pathname))
    $('[data-behavior~=project-teaser]').removeClass('d-none')

  if ($poller = $("#activities-poller")).length
    unless ActivitiesPoller.initialized
      ActivitiesPoller.init($poller)
      ActivitiesPoller.poll()

  # Disable form buttons after submitting them.
  $('form').submit (ev)->
    if !$('input[type=submit]', this).is('[data-behavior~=skip-auto-disable]')
      $('input[type=submit]', this).attr('disabled', 'disabled').val('Processing...')

  # Search form
  $('[data-behavior~=form-search]').hover ->
    $('[data-behavior~=search-query]').focus()

  submitSearch = ->
    if $('[data-behavior~=search-query]').val() != ''
      $('[data-behavior~=form-search]').submit()
      $('[data-behavior~=search-query]').val('Searching...')
      return false
    else
      $('[data-behavior~=search-query]').effect( "shake", { direction: "left", times: 2, distance: 5}, 'fast' ).focus();

  $('[data-behavior~=search-button]').on 'click', (e)->
    e.preventDefault()
    submitSearch()

  $('[data-behavior~=search-query]').on 'keypress', (e)->
    if e.which == 13
      submitSearch()

  # Toggle sidebar menu
  $('[data-behavior~=expandable-sidebar]').each ->
    new Sidebar($(this))

  # Collapsable div in sidebar collections
  if $('[data-behavior~=collapse-collection]').length
    $('[data-behavior~=collapse-collection]').click ->
      $this = $(this)
      $this.find('[data-behavior~=toggle-chevron]').toggleClass('fa-chevron-down fa-chevron-up')

      if $this.is('[data-behavior~=import-box]') && $($this.data('target')).innerHeight() == 0
        $($this.data('target')).find("input[type='text']:first").focus()

  # Scroll for more indicator functionality
  if $('[data-behavior~=restrict-height]').length
    checkOverflow = ->
      $('[data-behavior~=restrict-height]').each ->
        if $(this).is('[data-height~=match-prev]')
          prevContainer = $(this).parent().prev().children('[data-behavior~=content-container]').innerHeight()
          $(this).innerHeight(prevContainer)
        else if $(this).is('[data-height~=match-next]')
          nextContainer = $(this).parent().next().children('[data-behavior~=content-container]').innerHeight()
          $(this).innerHeight(nextContainer)

        if $(this).innerHeight() + 32 < $(this)[0].scrollHeight && $(this).innerHeight() > 100 # if container is > 100px and has overflowing content
          if $(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight # if already at the bottom
            return
          else
            $(this).find($('[data-behavior~=scroll-wrapper]')).removeClass('hidden');
        else
          $(this).find($('[data-behavior~=scroll-wrapper]')).addClass('hidden');
      return

    $('[data-behavior~=restrict-height]').append('<div class="scroll-more-wrapper hidden" data-behavior="scroll-wrapper"><span class="scroll-more">Scroll for more</span><span class="gradient"></span><span class="line"></span></div>')
    checkOverflow()

    $(window).resize ->
      checkOverflow()

    $('[data-behavior~=restrict-height]').on 'scroll', ->
      if $(this).scrollTop() + 64 + $(this).innerHeight() >= $(this)[0].scrollHeight
        $(this).find($('[data-behavior~=scroll-wrapper]')).addClass('hidden');
      else
        $(this).find($('[data-behavior~=scroll-wrapper]')).removeClass('hidden');

  # Disable turbo for on-page anchor links (prevents page from jumping to top and allows smooth-scrolling)
  if $('a[href^="#"]').length
    $('a[href^="#"]').each ->
      if !$(this).data('turbo')
        $(this).attr 'data-turbo', 'false'
      return

  # Smooth Scrolling - scroll to element on page load if hash present in current browser url
  if window.location.hash
    target = window.location.hash
    $(target)[0].scrollIntoView behavior: 'smooth'

  # Smooth Scrolling - scroll to element on click
  # Note: Parent element of anchor links needs: data-attribute="smooth-scroll-nav".
  #       This prevents unwanted smooth scrolling when switching tabs, etc.
  $(document).on 'click', '[data-behavior~=smooth-scroll-nav] a[href^="#"]', (event) ->
    event.preventDefault()
    history.pushState({}, '', this.href);
    $(this.hash)[0].scrollIntoView behavior: 'smooth'
    return
