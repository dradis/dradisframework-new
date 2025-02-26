function loadNotificationsDropdown($dropdown) {
  $.ajax({
    url: $dropdown.attr('href') + '.js',
    data: {
      project_id: $dropdown.data('projectId'),
    },
    dataType: 'script',
    method: 'GET',
    beforeSend: function () {
      var $container = $dropdown.next('div');
      $container.html('<div class="loader"></div>');
    },
  });
  $dropdown.off('click');
}

function initNotificationsDropdown() {
  var $dropdown = $('[data-behavior~=notifications-dropdown]');
  var navbarCollapsed = $('[data-behavior~=navbar-toggler]').is(':visible');

  if (navbarCollapsed) {
    $dropdown.off('click');
    $dropdown.removeAttr('data-bs-toggle');
    $dropdown.next('div').removeClass('show');
  } else {
    $dropdown.attr('data-bs-toggle', 'dropdown');
    $dropdown.on('click', function () {
      loadNotificationsDropdown($dropdown);
    });
  }
}

document.addEventListener('turbolinks:load', function () {
  initNotificationsDropdown();
});

// this is needed to ensure the notification link either shows a dropdown or
// navigates to notifications#index depending on navbar layout (mobile vs full)
window.addEventListener('resize', initNotificationsDropdown);
