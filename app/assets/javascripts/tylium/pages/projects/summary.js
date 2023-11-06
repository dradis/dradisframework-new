document.addEventListener('turbo:load', function () {
  if ($('body.projects.show').length) {
    $('a[data-bs-toggle="collapse"]').click(function () {
      if ($(this).hasClass('collapsed')) {
        $(this)
          .find('[data-behavior~=caret-icon]')
          .removeClass('fa-caret-up')
          .addClass('fa-caret-down');
      } else {
        $(this)
          .find('[data-behavior~=caret-icon]')
          .removeClass('fa-caret-down')
          .addClass('fa-caret-up');
      }
    });
  }
});
