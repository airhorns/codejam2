class ChartView
  UPDATE_INTERVAL: 1000
  SINCE: 0
  constructor: (@stock) ->
    window.chart?.remove()
    clearTimeout window.getNewData if window.getNewData?

    Highcharts.setOptions
      global:
        useUTC: false

    self = @
    object =
      animation: false
      chart:
        renderTo: "graph"
        events:
          load: ->
            window.getNewData = setInterval self.getNewData, self.UPDATE_INTERVAL

      navigator:
        enabled: false

      rangeSelector:
        buttonTheme:
          fill: 'none'
          stroke: 'none'
          style:
            color: '#039'
            fontWeight: 'bold'
          states:
            hover:
              fill: 'white'
            select:
              style:
                color: 'white'
        inputStyle:
          color: '#039'
          fontWeight: 'bold'
        labelStyle:
          color: 'silver'
          fontWeight: 'bold'
        selected: 1
        buttons: [
          count: 1
          type: "second"
          text: "1S"
        ,
          count: 5
          type: "second"
          text: "5S"
        ,
          count: 1
          type: "minute"
          text: "1M"
        ,
          type: "all"
          text: "All"
        ]
        inputEnabled: false
        selected: 3

      title:
        text: "Price over time for #{stock}"

      exporting:
        enabled: false

      series: [
        name: "#{stock} price"
        data: []
        tooltip:
          yDecimals: 2
      ]

    @chart = new Highcharts.StockChart(object)
    @getNewData()

  remove: -> @chart.destroy()

  getNewData: =>
    $.ajax
      url: "/#{@stock}/trades.json"
      dataType: 'json'
      data:
        since: @since
      success: (data) =>
        series = @chart.series[0]
        points = for execution in data.trades
          point =
            x: Date.parse(execution.created)
            y: execution.price
          debugger unless point.x > 0 && point.y > 0
          series.addPoint point, false, false
          point

        if data.trades.length > 0
          @since = parseInt(data.trades[data.trades.length - 1].id) + 1
          @chart.redraw()
        true

      error: -> console.error(arguments)

$ ->
  $.ajax
    url: '/stocks.json'
    dataType: 'json'
    success: (data) ->
      for stock in data.stocks
        option = $('<option>')
        option.html(stock)
        $('#stock').append(option)

      $('#stock').change ->
        window.chart = new ChartView($("#stock option:selected").html())
