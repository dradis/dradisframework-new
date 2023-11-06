document.addEventListener('turbo:load', function () {
  if ($('body.upload.index').length) {
    $('[data-behavior~=tool-select]').on('change', function () {
      let toolsWithInheritedState = [
        'Dradis::Plugins::Projects::Upload::Package',
        'Dradis::Plugins::Projects::Upload::Template',
      ];

      if (toolsWithInheritedState.includes($(this).val())) {
        $('[data-behavior~=state-select]')
          .attr('disabled', true)
          .addClass('disabled')
          .find('option:selected')
          .text('Imported from file');
      } else {
        let $option = $('[data-behavior~=state-select]').find('option:selected');
        let state = $option.val().replaceAll('_', ' ');

        $('[data-behavior~=state-select]')
          .attr('disabled', false)
          .removeClass('disabled');

        $option.text(state.charAt(0).toUpperCase() + state.slice(1));
      }
    });
  }
});
