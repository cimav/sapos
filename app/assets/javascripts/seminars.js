var model_name = 'advance';
$(document).ready(function() {
  liveSearch();

  $("#advance_student_id").live("change", function(){
    $("#advance-data").html("Cargando...")
    var form = $("#item-new-form");
    
    var url = location.pathname + "/advance_data";
    var formData = form.serialize();
    $.get(url, formData, function(html) {
      $("#advance-data").html(html)
    });
  });
  
  $("#alert-dialog").dialog({ 
    autoOpen: false, 
    width: 300, 
    height: 145, 
    modal:true
  });

  $("#alert-dialog-button").live("click", function (){
    $("#alert-dialog").dialog('close');
  });

  $("#item-new-form").live("ajax:beforeSend",function(evt,xhr,settings){
   sh = $("#session_hour").val();
   sm = $("#session_minutes").val();
 
   if(sh==""){
     $("#alert-dialog-content").html("Debe capturar la hora");
     $("#alert-dialog").dialog('open');
     return false;
   }else if(sm==""){
     $("#alert-dialog-content").html("Debe capturar los minutos"); 
     $("#alert-dialog").dialog('open');
     return false;
   }
  });
});

function start_datepicker()
{
  $.datepicker.setDefaults($.datepicker.regional["es"]);
  var config = {
    changeMonth: true,
    changeYear: true,
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    minDate: '-80Y',
    maxDate: '+2Y',
  };

  $( "#advance_advance_date" ).datepicker(config);
}

function initializeSearchForm(){
  $("#supervisor option[value=0]").attr("selected", true);
}
