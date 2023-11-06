document.addEventListener('turbo:load', function () {
  if ($('[data-behavior~=state-radio]').length) {
    function updateBtn($selectedRadio) {
      var selectedState = $selectedRadio
        .parent()
        .find('[data-behavior~=state-label]');

      var $stateBtn = $selectedRadio
        .closest('[data-behavior~=btn-states]')
        .find('[data-behavior~=state-button]');

      $stateBtn.text(selectedState.text());
      $stateBtn.parent().attr('data-state', $selectedRadio.val());
    }

    $('[data-behavior~=state-radio]').on('change', function () {
      updateBtn($(this));
    });
  }
});
