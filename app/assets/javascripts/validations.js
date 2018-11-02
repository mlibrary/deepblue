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
