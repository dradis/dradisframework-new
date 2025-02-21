#
# Interactive Donut Charts
# http://bl.ocks.org/erichoco/6694616
#

class @DonutChart
  # -- Constructor ------------------------------------------------------------
  constructor: (chartId)->
    @container  = d3.select(chartId)
    @$container = $(chartId)
    @color      = d3.scaleOrdinal(d3.schemeCategory20)

    @chart_m = null
    @chart_r = null

    # -- Private methods ------------------------------------------------------
    @_animatePath = (path, direction)->
      switch direction
        when 0
          path.transition()
            .duration(500)
            .ease(d3.easeBounce)
            .attr('d',
              d3.arc()
                .innerRadius(@chart_r * 0.7)
                .outerRadius(@chart_r)
            )

        when 1
          path.transition()
            .attr('d',
              d3.arc()
                .innerRadius(@chart_r * 0.7)
                .outerRadius(@chart_r * 1.08)
            )

    @_createCenter = ->
      donuts = @container.selectAll('.donut')

      donuts.append("a")
        .attr("xlink:href", @$container.data('url'))
        .append("svg:circle")
        .attr("r", @chart_r * 0.6)
        .style("fill", "#E7E7E7")
        # .on(eventObj);

      textElement = donuts
        .append("a")
        .attr("xlink:href", @$container.data('url'))
        .append('text')
        .attr('class', 'center-txt type')
        .attr('y', @chart_r * -0.16)
        .attr('text-anchor', 'middle')
        .style('font-weight', 'bold')
        .text (data, i) ->
          return data.type

      @_wrapCenterText(textElement)

      donuts.append('text')
        .attr('class', 'center-txt value')
        .attr('text-anchor', 'middle')

      donuts.append('text')
        .attr('class', 'center-txt percentage')
        .attr('y', @chart_r * 0.16)
        .attr('text-anchor', 'middle')
        .style('fill', '#A2A2A2')

    @_createLegend = (categories) ->
      @container.append('svg')
        .attr('class', 'legend')
        .attr('width', '100%')
        # .attr('height', 50)
        .attr('height', categories.length * 30)

      circle_radius = 6

      legend = @container.select('.legend')
                 .selectAll('g')
                   .data(categories)
                 .enter().append('g')
                   .attr 'transform', (d, i) ->
                     # return 'translate(' + (i * 150 + 50) + ', 10)'
                     return 'translate(30, ' + (i * circle_radius * 4 + 10) + ')'

      legend.append('circle')
        .attr('class', 'legend-icon')
        .attr('r', circle_radius)
        .style 'fill', (d, i) =>
          return @color(i)

      legend.append('text')
        .attr('dx', '1em')
        .attr('dy', '.3em')
        .text (d)->
          return d

    @_getDataCategories = (dataset)->
      names = new Array()
      for i in [0...dataset[0].data.length]
        names.push(dataset[0].data[i].category)

      return names

    @_getDataSet = ->
      type = ['Users']#, 'Avg Upload', 'Avg Files Shared']
      unit = ['M', 'GB', '']
      cat  = ['Google Drive', 'Dropbox', 'iCloud', 'OneDrive', 'Box']

      dataset = new Array()

      for i in [0...type.length]
        data = new Array()
        total = 0

        for j in [0...cat.length]
          value = Math.random()*10*(3-i)
          total += value

          data.push({
            "cat": cat[j],
            "val": value
          })

        dataset.push({
          "type": type[i],
          "unit": unit[i],
          "data": data,
          "total": total
        })

      return dataset

    @_setCenterText = (chart)->
      clickedData = chart.selectAll('.clicked').data()
      sum = d3.sum(clickedData, (d) ->
        return d.data.value
      )

      chart.select('.type')
        .text (d) ->
          switch clickedData.length
            when 0
              d.type
            when 1
              clickedData[0].data.category
            else
              'Combined'

      @_wrapCenterText(chart.select('.type'))

      chart.select('.value')
        .text (d) ->
          if sum
            # sum.toFixed(1) + d.unit
            sum.toFixed(0)
          else
            # d.total.toFixed(1) + d.unit
            d.total.toFixed(0)

      chart.select('.percentage')
        .text (d) ->
          if sum
            (sum / d.total*100).toFixed(2) + '%'
          else
            ''

    @_wrapCenterText = (el) ->
      text = el.text().split(' ')
      lineNumber = 0
      y = el.attr('y')

      el.text('')
      for word in text
        el.append('tspan')
          .attr('x', 0)
          .attr('y', y)
          .attr('dy', lineNumber++ + "em")
          .text(word)

    @_updateDonut = ->
      that = this
      eventCallbacks = {
        'mouseover': (datum, index, nodes) ->
            that._animatePath(d3.select(this), 1)

            thisDonut = that.container.select('.type0')

            thisDonut.select('.value').style('display', 'block')

            thisDonut.select('.type').text (donut_d)->
                # return d.data.val.toFixed(1) + donut_d.unit
                return datum.data.category

            thisDonut.select('.value').text (donut_d)->
                # return d.data.val.toFixed(1) + donut_d.unit
                return datum.data.value.toFixed(0)

            thisDonut.select('.percentage').text (donut_d) ->
                return (datum.data.value / donut_d.total*100).toFixed(2) + '%'

        , 'mouseout': (datum, index, nodes) ->
            thisPath = d3.select(this)

            if (!thisPath.classed('clicked'))
              that._animatePath(thisPath, 0)

            thisDonut = that.container.select('.type0')
            that._setCenterText(thisDonut)

            if (thisDonut.selectAll('.clicked').empty())
              thisDonut.select('.value').style('display', 'none')

            # thisDonut.select('.value').text('')

        , 'click': (datum, index, nodes) ->
            thisDonut = that.container.select('.type0')

            # if (0 == thisDonut.selectAll('.clicked')[0].length)
            #   thisDonut.select('circle').on('click')()

            thisPath = d3.select(this)
            clicked  = thisPath.classed('clicked')
            that._animatePath(thisPath, ~~(!clicked))
            thisPath.classed('clicked', !clicked)

            that._setCenterText(thisDonut)

            if (clicked)
              if (thisDonut.selectAll('.clicked').empty())
                thisDonut.select('.value').style('display', 'none')
      }


      pie = d3.pie()
        .sort(null)
        .value (d) ->
          return d.value

      that = this
      arc = d3.arc()
        .innerRadius(@chart_r * 0.7)
        .outerRadius ->
          if (d3.select(this).classed('clicked'))
            return that.chart_r * 1.08
          else
            return that.chart_r


      paths = @container.selectAll('.donut')
        .selectAll('path')
        .data (d, i)->
          return pie(d.data)

      paths
        .transition()
        .duration(1000)
        .attr('d', arc)


      paths.enter()
        .append('svg:path')
          .attr('d', arc)
          .style('fill', (d, i) -> return that.color(i))
          .style('stroke', '#FFFFFF')
          .on('mouseover', eventCallbacks.mouseover )
          .on('mouseout', eventCallbacks.mouseout )
          .on('click', eventCallbacks.click )

      paths.exit().remove()

      # resetAllCenterText()
    # -- /Private methods -----------------------------------------------------


    # @dataset    = @_getDataSet()
    @dataset = @$container.data('stats')
  # -- /Constructor -----------------------------------------------------------

  # -- Public methods ---------------------------------------------------------
  draw: ->
    @chart_m = @$container.innerWidth() / @dataset.length / 2 * 0.14
    @chart_r = @$container.innerWidth() / @dataset.length / 2 * 0.85

    # Donut chart
    @chart = @container.selectAll('.donut')
              .data(@dataset)
              .enter().append('svg:svg')
                .attr('width', (@chart_r + @chart_m) * 2)
                .attr('height', (@chart_r + @chart_m) * 2)
              .append('svg:g')
                .attr('class', (d, i) ->
                  return 'donut type' + i
                )
                .attr('transform', 'translate(' + (@chart_r + @chart_m) + ',' + (@chart_r + @chart_m) + ')')


    @_createLegend(@_getDataCategories(@dataset))
    @_createCenter()
    @_updateDonut()
