document.addEventListener('turbo:load', function () {
  if ($('[data-behavior~=qa-viewer]').length) {
    $('[data-qa-visible]').each(function () {
      $(this).toggleClass('d-none', $(this).data('qa-visible') === false);
    });
  }
});
