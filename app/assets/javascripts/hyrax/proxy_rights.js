(function( $ ){

  $.fn.proxyRights = function( options ) {

    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    var $container = this;

    function addContributor(name, user_key, grantor) {
      data = {name: name, user_key: user_key}

      $.ajax({
        type: "POST",
        url: '/data/users/'+grantor+'/depositors',  // monkey: Rails.configuration.relative_url_root
        dataType: 'json',
        data: {grantee_id: user_key},
        success: function (data) {
          if (data.name !== undefined) {
            row = rowTemplate(data);
            $('#authorizedProxies tbody', $container).append(row);
            if (settings.afterAdd)
              settings.afterAdd(this, cloneElem);
          }
        },
        error: function (data) {
          if (data.responseJSON !== undefined) {
            errorMsg = data.responseJSON.description;
            $('#errorMsg').text(errorMsg);
            $('#proxy-deny-modal').modal('show');
            return;
          }
        }
      })
      return false;
    }

    function removeContributor(event) {
      event.preventDefault();
      $.ajax({
        url: $(this).closest('a').prop('href'),
        type: "post",
        dataType: "json",
        data: {"_method":"delete"}
      });
      $(this).closest('tr').remove();
      return false;
    }

    function rowTemplate (data) {
      return '<tr>'+
                '<td class="depositor-name">'+data.name+'</td>'+
                '<td><a class="remove-proxy-button btn btn-danger" data-method="delete" href="'+data.delete_path+'" rel="nofollow">'+
                $('#delete_button_label').data('label')+'</a>'+
                '</td>'+
              '</tr>'
    }

    $("#user").userSearch();
    $("#user").on("change", function() {
      // Remove the choice from the select2 widget and put it in the table.
      obj = $("#user").select2("data")
      grantor = $('#user').data('grantor')
      $("#user").select2("val", '')
      addContributor(obj.text, obj.user_key, grantor);
    });

    $('body').on('click', 'a.remove-proxy-button', removeContributor);

  };

})( jQuery );

Blacklight.onLoad(function() {
  $('.proxy-rights').proxyRights();
});
