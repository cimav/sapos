var model_name = 'applicant';
 
$(document).ready(function() {
  $.datepicker.setDefaults($.datepicker.regional["es"]);
    var config = {
    changeMonth: true,
    changeYear: true,
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    minDate: '-80Y',
    maxDate: '+2Y',
  };

  $('#start_date').datepicker(config);
  $('#end_date').datepicker(config);

  $('#auth_1').click(function(){
    $('#data').show();
  });

  
  $('#auth_2').click(function(){
    $('#data').hide();
  });
  
  $('#recom-send').click(function(){
    if($('#auth_1').prop("checked"))
    {
       start_date_val = $('#start_date').val();
       end_date_val   = $('#end_date').val();
       activity       = $('#activity_area').val();

       start_date_splitted = start_date_val.split("-");
       year  = Number(start_date_splitted[0]);
       month = Number(start_date_splitted[1]);
       day   = Number(start_date_splitted[2]);
       
       
       end_date_splitted = end_date_val.split("-");
       year  = Number(end_date_splitted[0]);
       month = Number(end_date_splitted[1]);
       day   = Number(end_date_splitted[2]);

       start_date = new Date(start_date_splitted[0],start_date_splitted[1],start_date_splitted[2]);
       end_date   = new Date(end_date_splitted[0],end_date_splitted[1],end_date_splitted[2]);


       if(start_date.getTime() >= end_date.getTime())
       {
         alert("La fecha inicial no puede ser mayor o igual que la inicial");
         return false;
       }

       //alert(start_date.getFullYear()+'|'+start_date.getMonth()+'|'+start_date.getDate());

       if((start_date=='')||(end_date=='')||(activity==''))
       {
          alert("Todos los campos son obligatorios")
          return false;
       }

      $('#advance-grades-form').submit();
    }
    else if($('#auth_2').prop("checked"))
    {
      $('#advance-grades-form').submit();
    }
    else
    {
      alert("Debe elegir una opción");
      return false;
    }
  });
});



