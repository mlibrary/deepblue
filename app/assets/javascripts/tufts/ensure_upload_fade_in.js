// This  will catch the change event on document and add 'in' class to 
// template-upload, sso that the files that can't be uplaoded because
// the max count has been reached, will show up on the screen.  Not quite sure 
// why they don't show up, but this will do the trick.  I  was expecting a 
// 'fileuploadstop' event to show up,  but it did not.  I saw this change envent when I did 
// monitorEvents(document.body) in the Console of the development tools.  This
// is a great debugging tool to see what events show up.
// I added the timeout because on Safari, the 'in' class was not being applied
// in time. 
//
$(document).on('change', function (e, data) {
  $(document).ready(function(){ 
    $('.template-upload').addClass('in')
    setTimeout(function(){ $('.template-upload').addClass('in') }, 500);
   });
})
