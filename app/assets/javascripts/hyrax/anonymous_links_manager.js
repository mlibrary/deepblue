(function( $ ){
    $.fn.anonymousLinks = function( options ) {

        var clipboard = new Clipboard('.copy-anonymous-link');

        var manager = {
            reload_table: function() {
                var url = $("table.anonymous-links tbody").data('url')
                $.get(url).done(function(data) {
                    $('table.anonymous-links tbody').html(data);
                });
            },

            create_link: function(caller) {
                $.post(caller.attr('href')).done(function(data) {
                    manager.reload_table()
                })
            },

            delete_link: function(caller) {
                $.ajax({
                    url: caller.attr('href'),
                    type: 'DELETE',
                    done: caller.parent('td').parent('tr').remove()
                })
            }
        };

        $('.generate-anonymous-link').click(function(event) {
            event.preventDefault()
            manager.create_link($(this))
            return false
        });

        $("table.anonymous-links tbody").on('click', '.delete-anonymous-link', function(event) {
            event.preventDefault()
            manager.delete_link($(this))
            return false;
        });

        clipboard.on('success', function(e) {
            $(e.trigger).tooltip('show');
            e.clearSelection();
        });

        return manager;

    };
})( jQuery );

Blacklight.onLoad(function () {
    $('.anonymous-links').anonymousLinks();
});
