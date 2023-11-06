document.addEventListener('turbo:load', function(){
  if ($('[data-behavior~=boards-summary]').length) {
    var $boardsSummary = $('[data-behavior~=boards-summary]');
    var url = $boardsSummary.data('url');

    // Add a loader before sending the request
    $boardsSummary.addClass('loading');

    fetch(url + '.json', {credentials: 'same-origin'}).
      then(response => response.json()).
      then(function(data) {
        if (data.length) {
          data.forEach(function(data){
            var board = data[0];
            var lists = data[1];
            var stats = [{
              data: lists,
              total: board.total,
              type: board.name
            }];

            $boardChart = $('<div/>', {
              id: 'methodology-board-' + board.id,
              class: 'pie-chart',
              'data-behavior': 'interactive-pie-chart',
              'data-stats': JSON.stringify(stats),
              'data-url': board.url
            });
            $boardChart.appendTo($boardsSummary);
          });

          $('[data-behavior~=interactive-pie-chart]').each(function(i, chart) {
            if ($(this).find('svg').length > 0) return;
            (new DonutChart('#' + $(chart).attr('id'))).draw();
          });
        }
      }).
      then(function() {
        // Remove the loader
        $boardsSummary.removeClass('loading');
      }).
      catch(function(error) { console.log(error); });
  }
});
