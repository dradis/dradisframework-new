document.addEventListener('turbo:load', function() {
  var $rtpValidation = $('[data-behavior~=rtp-validation]');

  if ($rtpValidation.length) {
    var uploader = $('[data-behavior~=uploader]').val();
    new RTPValidation({ rtpId: $rtpValidation.data('rtp-id'), uploader: uploader });
  }
})
