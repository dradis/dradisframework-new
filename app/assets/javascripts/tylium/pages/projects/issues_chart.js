document.addEventListener('turbo:load', function(){
  var $dataElement  = $('#issues-summary-data'),
      $chartElement = $('#issue-chart');

  if ($dataElement.length && $chartElement.find('svg').length == 0) {
    var margin = {top: 20, bottom: 30},
        width = 354;
        height = 180 - margin.top - margin.bottom;

    var x = d3.scaleBand().rangeRound([0, width]);

    var y = d3.scaleLinear()
        .range([height, 0]);

    var xAxis = d3.axisBottom(x)
        .tickSize(0);

    var svg = d3.select('#issue-chart').append('svg')
        .attr('width', width)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', 'translate(0,' + margin.top + ')');

    // --------------------------------------------------------- Data variables
    var tags        = $dataElement.data('tags');
    var issuesByTag = $dataElement.data('issues-count');
    var highest     = 0;
    var data        = [];
    var x_domain    = [];

    for (var key in tags){
      issuesCount = issuesByTag[key];
      highest = issuesCount > highest ? issuesCount : highest
      data.push({letter: tags[key][0], frequency: issuesCount});
      x_domain.push(tags[key][0]);
    }
    data.push({letter: 'N/A', frequency: issuesByTag['unassigned']})
    x_domain.push('N/A');

    var highest_y = Math.max(highest, issuesByTag['unassigned']);
    // -------------------------------------------------------- /Data variables

    x.domain(x_domain);

    y.domain([0, highest_y]);

    d3.selection.prototype.last = function() {
      return d3.select(
          this.nodes()[this.size() - 1]
      );
    };

    x_axis = svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0,' + height + ')')
        .call(xAxis);
    x_axis.selectAll("text").style("fill", "inherit");
    x_axis.selectAll("path").style("stroke", "none");
    x_axis.selectAll("text").last().style("fill", "#000");

    var bars = svg.append('g');

    bars.selectAll('rect')
        .data(data)
      .enter().append('rect')
        .attr('class', 'bar' )
        .attr('x', function(d) { return x(d.letter); })
        .attr('width', x.bandwidth())
        .attr('y', function(d) { return y(d.frequency); })
        .attr('height', function(d) { return height - y(d.frequency); });


    bars.selectAll('text')
        .data(data)
      .enter().append('text')
        .attr('x', function(d, i) { return x(d.letter) + x.bandwidth()/2; })
        .attr('y', function(d) { return y(d.frequency);})
        .attr('dy', -5)
        .attr('text-anchor', 'middle')
        .attr('class', 'counter' )
        .text(function(d) {return d.frequency;});

    var i = 0;
    for( var key in tags ){
      $($('.tick')[i]).attr('fill', tags[key][1]);
      $($('.bar')[i]).attr('fill', tags[key][1]);
      $($('.counter')[i]).attr('fill', tags[key][1]);
      i++;
    }

    $($('.tick')[tags.length]).attr('fill', '#ccc');
    $($('.bar')[tags.length]).attr('fill', '#ccc');
    $($('.counter')[tags.length]).attr('fill', '#ccc');
  }
});
