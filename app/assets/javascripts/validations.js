function checkemail(email)
{
   var regex=/\S+@\S+\.\S+/;
   if(!regex.test(email))
   {
       alert('Please enter valid email for Contact Information');
    }
 }

function checkdate(email)
{
   var regex=/\d{4}/;
   if(!regex.test(email))
   {
       alert('Please enter a valid date');
    }
 }

function movetofilestab()
{
  window.scrollTo(0, 0);
  $('a[href="#files"]').click()
  event.preventDefault();
}

function getContactUserParameters()
{
  var endtag = 0,i=0;
  var title = document.getElementById("data_set_title").value;
  var author = document.getElementById("data_set_creator").value;
  var url =  window.location;

  var url = window.location.origin + '/data/contact?title="' + title + '"&author="' + author + '"&url="' + url + '"';
  window.open(url);
}

//function validateVersioningFiles(inputFile) {
function validateVersioningFiles(inputFile,maxFileSize,maxFileSizeStr,expectedFileName) {
    var maxFileSizeErrorMessage = "This file exceeds the maximum allowed file size " + maxFileSizeStr;
    var renamedErrorMessage = "Can't rename the file: " + "'" + expectedFileName + "'";
    //var extErrorMessage = "Only image file with extension: .jpg, .jpeg, .gif or .png is allowed";
    //var allowedExtension = ["jpg", "jpeg", "gif", "png"];

    //var extName;
    //var maxFileSize = $(inputFile).dataset['max_file_size'];
    //var expectedFileName = $(inputFile).dataset['expected_file_name'];
    var maxFileSizeError = false;
    var renamedError = false;
    //var extError = false;

    $.each(inputFile.files, function() {
        if ( this.size && maxFileSize && this.size > parseInt(maxFileSize) ) { maxFileSizeError = true; };
        if ( this.name != expectedFileName ) { renamedError = true; }
        //extName = this.name.split('.').pop();
        //if ($.inArray(extName, allowedExtension) == -1) {extError=true;};
    });
    if ( maxFileSizeError ) {
        window.alert( maxFileSizeErrorMessage );
        $(inputFile).val('');
    };
    if ( renamedError ) {
        window.alert( renamedErrorMessage );
        $(inputFile).val('');
    };

    //if (extError) {
    //    window.alert(extErrorMessage);
    //    $(inputFile).val('');
    //};
}
