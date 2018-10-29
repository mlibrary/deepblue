function checkemail(email)
{
   var regex=/\S+@\S+\.\S+/;
   if(!regex.test(email))
   {
       alert('Please enter valid email for Contact Information');
    }
 }
