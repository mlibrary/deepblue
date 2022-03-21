$(document).on('turbolinks:load', function() {    
    var showChar = 300;
    var showCharAuthor = 1000;

    var moretext = "[more]";
    var lesstext = "[less]";
    var ellipsestext = "...";

    $(".more").each(function() {
      var content = $(this).html();
      if (content.length > showChar) {
        var c = content.substr(0, showChar);
        var h = content;
        var html =
          '<div class="truncate-text" style="display:block">' +
          c +
          '<span class="moreellipses">' +
          ellipsestext +
          '&nbsp;&nbsp;<a href="" class="moreless more">' + moretext + '</a></span></span></div><div class="truncate-text" style="display:none">' +
          h +
          '&nbsp;&nbsp;<a href="" class="moreless less">' + lesstext + '</a></span></div>';

        $(this).html(html);
      }
    });


    // This one is for the authors, since they have <a tags 
    // The showCharAuthor length has to be longer.
    $(".moreauthor").each(function() {
      var content = $(this).html();
      if (content.length > showCharAuthor) {
        var c = content.substr(0, showCharAuthor);
        var h = content;
        var html =
          '<div class="truncate-text" style="display:block">' +
          c.replace(/;[^,]+$/, "") +
          '<span class="moreellipses">' +
          ellipsestext +
          '&nbsp;&nbsp;<a href="" class="moreless more">' + moretext + '</a></span></span></div><div class="truncate-text" style="display:none">' +
          h +
          '&nbsp;&nbsp;<a href="" class="moreless less">' + lesstext + '</a></span></div>';

        $(this).html(html);
      }
    });

    $(".moreless").click(function() {
      var thisEl = $(this);
      var cT = thisEl.closest(".truncate-text");
      var tX = ".truncate-text";

      if (thisEl.hasClass("less")) {
        cT.prev(tX).toggle();
        cT.slideToggle();
      } else {
        cT.toggle();
        cT.next(tX).fadeToggle();
      }
      return false;
    });

    function start_substr(string, length) {
        var endtag = 0,i=0;
        for(i; i<string.length; i++)
        {
          if(string[i] == ">")
            endtag = i;
        }

        i = length;
        if (endtag > length)
        {
           i = endtag;
        }

        var newString = string.substring(0,(i+1));
        return newString;
    }
});