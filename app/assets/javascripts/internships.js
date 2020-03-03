var model_name = 'internship';

// ** On change Area
$('#area_s').live("change", function() {
  liveSearch();
});

// ** On change Institution
$('#institution').live("change", function() {
  liveSearch();
});

// ** On change Staff
$('#staff').live("change", function() {
  liveSearch();
});

// ** On change type
$('#internship_type').live("change", function() {
  liveSearch();
});

// ** On change campus
$('#campus').live("change", function() {
  liveSearch();
});

// ** On change Status
$('.status-cbs').live("click", function() {
  liveSearch();
});

// ** On change Status
$('#year').live("change", function() {
  liveSearch();
});


// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});


function initializeSearchForm() {
  $("#institution option[value=0]").attr("selected", true);
  $('#status_activos').attr('checked', true);
  $('#status_inactivos').attr('checked', false);
}

$(document).ready(function() {
  liveSearch();

  $('#iapplicant_button').live('click',function(){
    var day     = $('#date_day').val();
    var month   = $('#date_month').val();
    var year    = $('#date_year').val();
    var hour    = $('#date_hour').val();
    var minute  = $('#date_minutes').val();
    var text    = $('#iapplicant_contenido').val();
    var date    = day+"-"+month+"-"+year+"-"+hour+":"+minute

    var staff_id  = $('#iapplicant_staff').val();
    var i_id      = $('#aplicant_id').val();
    var data      = "date="+date+"&text="+text;
    var url       = "/internados/aspirantes/cita/"+i_id+"/"+staff_id

    $.ajax({
      type: 'POST',
      url: url,
      data: data,
      beforeSend: function( xhr ) {
        $('#iapplicant_button').hide();
        $('#img_load').show();
      },
      success: function(data){
        var jq  =  jQuery.parseJSON(data);
        alert("Mensaje Enviado");
        /*alert("success")*/
      },
      error: function(xhr, textStatus, error){
         var text = xhr.responseText;
         try{
           var jq   = jQuery.parseJSON(xhr.responseText);
           /*alert(text+"|"+jq.flash.error);*/
         }
         catch(e){
           alert("Error desconocido: "+e.message)
         }
      },
      complete: function(){
        $('#iapplicant_button').show();
        $('#img_load').hide();
      }
    });
  });
});
