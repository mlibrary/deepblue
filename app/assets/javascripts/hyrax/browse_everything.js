// Reviewed: hyrax4
//= require jquery.treetable
//= require browse_everything/behavior

// BEGIN: Update hyrax4 // comment out
// Show the files in the queue
// Blacklight.onLoad( function() {
//   // We need to check this because https://github.com/samvera/browse-everything/issues/169
//   if ($('#browse-btn').length > 0) {
//     $('#browse-btn').browseEverything()
//     .done(function(data) {
//       var evt = { isDefaultPrevented: function() { return false; } };
//       var files = $.map(data, function(d) { return { name: d.file_name, size: d.file_size, id: d.url } });
//       $.blueimp.fileupload.prototype.options.done.call($('#fileupload').fileupload(), evt, { result: { files: files }});
//     })
//   }
// });
// END: Update hyrax4 // comment out
function showBrowseEverythingFiles() {
  // We need to check this because https://github.com/samvera/browse-everything/issues/169
  if ($('#browse-btn').length > 0) {
    $('#browse-btn').browseEverything()
        .done(function(data) {
          var evt = { isDefaultPrevented: function() { return false; } };
          var files = $.map(data, function(d) { return { name: d.file_name, size: d.file_size, id: d.url } });
          $.blueimp.fileupload.prototype.options.done.call($('#fileupload').fileupload(), evt, { result: { files: files }});
        })
  }
}
$(document).on('click', '#browse-btn', showBrowseEverythingFiles);


