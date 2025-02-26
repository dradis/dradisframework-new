$(document).on('dradis:fetch', '[data-behavior~=fetch-comments]', function(event) {
  var fetchContainer = event.target;

  fetchContainer.querySelectorAll('[data-behavior~=comment-feed] [data-author-id]').forEach(function(item) {
    var currentUserId = document.querySelector('meta[name=current-user-id]').getAttribute('content');
    if (item.dataset.authorId === currentUserId) {
      var actions = item.querySelector('.actions');
      actions.classList.add('current_user');
    }
  });

  fetchContainer.querySelectorAll('[data-behavior~=mentionable]').forEach(function(item) {
    Mentions.init($(item));
  })
})
