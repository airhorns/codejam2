
  $(function() {
    var object;
    Highcharts.setOptions({
      global: {
        useUTC: false
      }
    });
    object = {
      chart: {
        renderTo: "graph",
        events: {
          load: function() {
            var series;
            series = this.series[0];
            return setInterval((function() {
              var x, y;
              x = (new Date()).getTime();
              y = Math.round(Math.random() * 100);
              return series.addPoint([x, y], true, true);
            }), 3000);
          }
        }
      },
      rangeSelector: {
        buttons: [
          {
            count: 1,
            type: "minute",
            text: "1M"
          }, {
            count: 5,
            type: "minute",
            text: "5M"
          }, {
            type: "all",
            text: "All"
          }
        ]
      },
      inputEnabled: false,
      selected: 0
    };
    return {
      title: {
        text: "Live random data"
      },
      exporting: {
        enabled: false
      },
      series: [
        {
          name: "Random data",
          data: (function() {
            var data, i, time;
            data = [];
            time = (new Date()).getTime();
            i = void 0;
            i = -999;
            while (i <= 0) {
              data.push({
                x: time + i * 1000,
                y: Math.round(Math.random() * 100)
              });
              i++;
            }
            return data;
          })()
        }
      ]
    };
  }, window.chart = new Highcharts.StockChart(object));
