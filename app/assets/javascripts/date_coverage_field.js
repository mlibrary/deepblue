$(document).on('turbolinks:load', function() {

  $( document ).ready(function() {
    $(".date-add-coverage-button").click(function() {
      toggleDateCoverage();
      $("#date_coverage_end_year").focus();
    });

    $(".date-reset").click(function() {
      // clear end date values
      $("#date_coverage_end_year").val('');
      $("#date_coverage_end_month").val('--');
      $("#date_coverage_end_day").val('--');

      toggleDateCoverage();
      $("#date_coverage_begin_year").focus();
    });

    function toggleDateCoverage() {
      $(".date-coverage-element").toggleClass('hidden');
    }

    $("#date_coverage_begin_year").blur(function() {
      updateDayMenu('begin');
    });

    $("#date_coverage_begin_month").change(function() {
      updateDayMenu('begin');
    });

    $("#date_coverage_end_year").blur(function() {
      updateDayMenu('end');
    });

    $("#date_coverage_end_month").change(function() {
      updateDayMenu('end');
    });

    function updateDayMenu(id) {
      var el = document.getElementById('date_coverage_'+id+'_year');
      var yearStr = el.value;
      if (!/^\d{1,4}$/.test(yearStr))
        return;
      var year = parseInt(yearStr, 10);
      el = document.getElementById('date_coverage_'+id+'_month');
      var month = parseInt(el.value, 10);
      var monthLength = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      // Adjust for leap years
      if (year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)) {
        monthLength[1] = 29;
      }
      var days = monthLength[month - 1];
      el = document.getElementById('date_coverage_'+id+'_day');
      // Remove or add days from/to end of select
      // until value of last one is the number of days.
      var sanity = 0; // In case while(true) spazzes out.
      while (true)
      {
        var val = parseInt(el[el.length-1].value, 10);
        if (val>days) {
          el.remove(el.length-1);
        }
        else {
          if (val<days) {
            var opt = document.createElement("option");
            opt.text = val+1;
            opt.value = val+1;
            el.add(opt);
          }
          else {
            break;
          }
        }
        sanity++;
        if (sanity >= 100) {
          break;
        }
      }
    }
  });
});
