$(document).on('dradis:fetch', '[data-behavior~=fetch-subscriptions]', function(event) {
  var fetchContainer = event.target;

  fetchContainer.querySelectorAll('[data-behavior~=subscription-actions]').forEach(function(item) {
    // Vanilla js returns a string while jquery returns a boolean instead
    if (item.dataset.subscribed === 'true') {
      document.querySelectorAll('[data-behavior=unsubscribe]').forEach(function(item) {
        item.classList.remove('d-none');
      });
    } else {
      document.querySelectorAll('[data-behavior=subscribe]').forEach(function(item) {
        item.classList.remove('d-none');
      });
    }
  });
});
