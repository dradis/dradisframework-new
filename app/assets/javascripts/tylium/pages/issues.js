document.addEventListener('turbo:load', function () {
  if ($('body.issues.index').length) {
    $('[data-behavior~=issues-dropdown-toggle]').on('click', function (e) {
      e.stopPropagation();
      new bootstrap.Dropdown($('[data-name~=issues]')).show();
    });
  }
});
