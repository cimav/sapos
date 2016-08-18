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
       start_date = $('#start_date').val();
       end_date   = $('#end_date').val();
       activity   = $('#activity_area').val();
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

  $('#advance-grades-form').submit();

});



