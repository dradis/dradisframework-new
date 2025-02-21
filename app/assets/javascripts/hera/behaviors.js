document.addEventListener('turbolinks:load', function () {
  // Activate jQuery.breadCrumbs
  $('.breadcrumb').breadcrumbs({
    tree: $('.main-sidebar .tree-navigation'),
  });

  // Activate jQuery.treeNav
  $('.tree-navigation').treeNav();

  // Activate jQuery.treeModal
  $('.modal-node-selection-form').treeModal();

  // Focus first input on modal window display.
  $('.modal').on('shown.bs.modal', function () {
    $(this).find('input:text:visible:first').focus();
  });

  // If project id is changed in project path
  if (!/^\/projects\/1(\/|$)/.test(window.location.pathname)) {
    $('[data-behavior~=project-teaser]').removeClass('d-none');
  }

  if ($('#activities-poller').length) {
    if (!ActivitiesPoller.initialized) {
      ActivitiesPoller.init($('#activities-poller'));
      ActivitiesPoller.poll();
    }
  }

  // Disable form buttons after submitting them.
  $('form').submit(function (ev) {
    if (
      !$('input[type=submit]', this).is('[data-behavior~=skip-auto-disable]')
    ) {
      $('input[type=submit]', this)
        .attr('disabled', 'disabled')
        .val('Processing...');
    }
  });

  // Toggle sidebar menu
  $('[data-behavior~=sidebar]').each(function () {
    new Sidebar($(this));
  });

  // Disable turbolinks for on-page anchor links (prevents page from jumping to top and allows smooth-scrolling)
  if ($('a[href^="#"]').length) {
    $('a[href^="#"]').each(function () {
      if (!$(this).data('turbolinks')) {
        $(this).attr('data-turbolinks', 'false');
      }
    });
  }

  // Smooth Scrolling - scroll to element on page load if hash present in current browser url
  if (window.location.hash) {
    const target = window.location.hash;
    $(target)[0].scrollIntoView({ behavior: 'smooth' });
  }
});

// Behaviors that get reinitialized on fetch
(function ($, window) {
  function initBehaviors(parentElement) {
    // Activate jQuery.Textile
    $(parentElement).find('.textile').textile();

    // Activate DataTables
    $(parentElement)
      .find('[data-behavior~=dradis-datatable]')
      .each(function () {
        new DradisDatatable(this);
      });

    // Activate Rich Toolbars for the editor
    $(parentElement)
      .find('[data-behavior~=rich-toolbar]')
      .each(function () {
        new EditorToolbar($(this));

        // Activate QuoteSelector after Rich toolbars
        // This can be globally scoped because the QuoteSelector does not allow
        // double binding
        $('[data-behavior~=content-textile]').each(function () {
          new QuoteSelector(this);
        });
      });

    // Activate local auto save
    $(parentElement)
      .find('[data-behavior~=local-auto-save]')
      .each(function () {
        new LocalAutoSave(this);
      });

    // Fetch content
    $(parentElement)
      .find('[data-behavior~=fetch]')
      .each(function () {
        var that = this;
        $.ajax(that.dataset.path, { credentials: 'include' })
          .then(function (response) {
            return response;
          })
          .then(function (html) {
            $(that).html(html);
            $(that).trigger('dradis:fetch');
            initBehaviors(that);
          });
      });

    // Init Bootstrap tooltips with 1ms delay for tooltips within <script type='text/x-tmpl'>
    setTimeout(function () {
      const tooltipTriggerList = document.querySelectorAll(
        '[data-bs-toggle="tooltip"]'
      );
      [...tooltipTriggerList].map(
        (tooltipTriggerEl) => new bootstrap.Tooltip(tooltipTriggerEl)
      );
    }, 1);

    // Navigate to tab
    let searchParams = new URLSearchParams(window.location.search);
    if (searchParams.has('tab')) {
      let tab = searchParams.get('tab');
      $($(`[data-bs-toggle~=tab][href="#${tab}"]`)).tab('show');
    }

    // Update address bar with current tab param
    $(parentElement)
      .find('[data-bs-toggle~=tab]')
      .on('shown.bs.tab', function (e) {
        let currentTab = $(e.target).attr('href').substring(1);
        searchParams.set('tab', currentTab);
        let urlWithTab = `?${searchParams.toString()}`;
        history.pushState(
          { turbolinks: true, url: urlWithTab },
          '',
          urlWithTab
        );
      });

    // Initialize clipboard.js
    const clipboard = new Clipboard(
      parentElement.querySelectorAll('[data-clipboard-text]')
    );

    clipboard.on('success', function (e) {
      const $copyBtn = $(e.trigger);
      e.clearSelection();
      $copyBtn.tooltip({
        placement: 'bottom',
        title: 'Copied to clipboard!',
        trigger: 'manual',
      });
      $copyBtn.tooltip('show');
      setTimeout(function () {
        $copyBtn.tooltip('hide');
      }, 1000);
    });

    clipboard.on('error', function (e) {
      const actionKey = e.action === 'cut' ? 'X' : 'C',
        $copyBtn = $(e.trigger);
      let actionMsg;

      if (/Mac/i.test(navigator.userAgent)) {
        actionMsg = 'Press ⌘-' + actionKey + ' to ' + e.action;
      } else {
        actionMsg = 'Press Ctrl-' + actionKey + ' to ' + e.action;
      }

      $copyBtn.tooltip({
        placement: 'bottom',
        title: actionMsg,
        trigger: 'manual',
      });
      $copyBtn.tooltip('show');
      setTimeout(function () {
        $copyBtn.tooltip('hide');
      }, 1000);
    });

    // Sortable lists
    $('[data-behavior~=ui-sortable]').sortable({
      axis: 'y',
      containment: 'parent',
      cursor: 'grabbing',
      handle: '.fa-grip-vertical',
      update: function () {
        $.post(
          $(this).data('sort-url'),
          $(this).sortable('serialize', { key: 'sorted_ids[]' })
        );
      },
    });

    window.initBehaviors = initBehaviors;
  }

  document.addEventListener('turbolinks:load', function () {
    initBehaviors(document.querySelector('body'));
  });

  // Because this is an event and not a data-driven behavior, we can leave it
  // out of initBehaviors and attach the listener to document directly.
  //
  // In particular we're after jquery.textile forms that get rendered post page
  // load via ajax.
  $(document).on('textile:formLoaded', '.textile-form', function (event) {
    // We trigger a single formLoaded event for the containing form, but we
    // have to attach EditorToolbar to individual textareas within it.
    $(event.target)
      .find('[data-behavior~=rich-toolbar]')
      .each(function () {
        new EditorToolbar($(this));
      });
  });
})($, window);
