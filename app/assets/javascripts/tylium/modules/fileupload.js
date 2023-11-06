// jQuery.fileUpload  - handles attachment uploads (gem: jquery-fileupload-rails)

function fileUploadInit() {
  $('[data-behavior~=jquery-upload]').fileupload({
     autoUpload: true,
     dropZone: function(){ return $('[data-behavior~=drop-zone]') },
     pasteZone: function(){ return $('[data-behavior~=drop-zone]') },
     singleFileUploads: true,
     destroy: function(e, data) {
       if (confirm('Are you sure?\n\nProceeding will delete this attachment from the associated node.')) {
         $.blueimp.fileupload.prototype.options.destroy.call(this, e, data);
       }
     }
  }).on('fileuploadadd', function (e, data) {
    // data.$textarea is added to the input field owned by the editor and is
    // only present when the image button is clicked. Copying, or dragging does
    // not append the attribute.
    var $textarea = (e.originalEvent !== undefined) ? $(e.originalEvent.target) : data.$textarea;

    if ($textarea.is($('[data-behavior~=rich-toolbar]'))) {
      var editorToolbar = $textarea.data('editorToolbar');
      data.replaceImagePlaceholder = editorToolbar.replaceImagePlaceholder.bind(editorToolbar);

      $.each(data.files, editorToolbar.insertImagePlaceholder.bind(editorToolbar));
    }
  }).on('fileuploaddone', function (e, data) {
    if (data.replaceImagePlaceholder !== undefined) {
      $.each(data.files, data.replaceImagePlaceholder.bind(null, data));
    }
  });
}

document.addEventListener("turbo:load", function() {
  // Bind fileUpload on page load.
  fileUploadInit();
});

// Un-bind fileUpload on page unload.
document.addEventListener('turbo:before-cache', function() {
  $('[data-behavior~=jquery-upload]').each(function() {
    $(this).fileupload('destroy');
  });
});
