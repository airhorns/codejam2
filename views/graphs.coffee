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
      chart:
        renderTo: "graph"
        events:
          load: ->
            series = @series[0]
            window.getNewData = setInterval self.getNewData, self.UPDATE_INTERVAL

      rangeSelector:
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
      ]

    @chart = new Highcharts.StockChart(object)
    @getNewData()

  remove: -> @chart.remove()

  getNewData: =>
    $.ajax
      url: "/#{@stock}/trades.json"
      dataType: 'json'
      data:
        since: @since
      success: (data) =>
        series = @chart.series[0]
        for execution in data.trades
          series.addPoint
            x: Date.parse(execution.created)
            y: execution.price
          , false
        if data.trades.length > 0
          @since = parseInt(data.trades[data.trades.length - 1].id) + 1
        @chart.redraw()
        true

      error: -> console.error(arguments)

$ ->
  window.chart = new ChartView("ABLE")
