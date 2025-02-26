(function(window) {
  window.Mentions = {
    init: function(elements) {
      fallbackImage = $('meta[name=mentionable-users]').data('fallback-image');

      tribute = new Tribute({
        allowSpaces: function() { return false },
        menuItemTemplate: function(item) {
          return '<img src="' + item.original.avatar_url + '" width="24px" height="24px" onerror="this.src = \'' + fallbackImage + '\';"> ' + item.string
        },
        noMatchTemplate: function() { return '' },
        values: JSON.parse($('meta[name=mentionable-users]').attr('content'))
      });

      $('[data-behavior~=mentions-scroll]').scroll(function(){
        tribute.hideMenu();
      });

      tribute.attach(elements);
    }
  }
})(window);
