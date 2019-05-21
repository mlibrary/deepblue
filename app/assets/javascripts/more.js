$(document).on('turbolinks:load', function() {    
    var showChar = 300;
    var ellipsestext = "...";
    var moretext = "[more]";
    var lesstext = "[less]";
     $('.more').each(function() {
        var content = $(this).html();
 
        if(content.length > showChar) {
            var c = start_substr (content, showChar)
            var h = content.substr(c.length, content.length - c.length);
            if (h != "") {
                var html = c + '<span class="moreellipses">' + ellipsestext + '</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="" class="morelink">' + moretext + '</a></span>';
                $(this).html(html);
            }
        }
    });
     $(".morelink").click(function(){
        if($(this).hasClass("less")) {
            $(this).removeClass("less");
            $(this).html(moretext);
        } else {
            $(this).addClass("less"); 
            $(this).html(lesstext);
        }
         $(this).parent().prev().toggle();
        $(this).prev().toggle();
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