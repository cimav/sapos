var model_name = 'applicant';
$(document).ready(function() {
  $("#application_button").live("click",function(){
    $('#cancel_button').hide();
    var app_id = $("#applicant_id").val();
    window.location="/internados/aspirantes/descargar/solicitud/"+app_id;
  });
  
  $("#cancel_button").live("click",function(){
    $('.terms').hide();
    $('.header').show();
    $('.fields_requested').show();
    $('#continue_button').show();
  });

  $("#continue_button").live("click",function(){
    $('.terms').show();
    $('.header').hide();
    $('.fields_requested').hide();
    $(this).hide();
  });

  var files_req_missing  =  $(".fields_requested .field_requested_document[required=1] .img-ok:hidden")
  if(files_req_missing.length==0){
     $("#continue_button").show();
  }else{
     $("#continue_button").hide();
  }

  $(".logout-button").live("click", function(){
    window.location="/internados/aspirantes/applicant_logout";
  });
});//document.ready
/********************* FUNCIONS ****************************/
