var model_name = 'applicant';
$(document).ready(function() {
  $("#application_button").live("click",function(){
    var app_id = $("#applicant_id").val();
    window.location="/aspirantes/descargar/solicitud/"+app_id;
  });

  var rd  = $(".fields_requested .field_requested_document")
  var rbd = $(".fields_requested .field_requested_document .img-ok:hidden")
  if(rbd.length==0){
     $(".terms").show();
  }
});//document.ready
/********************* FUNCIONS ****************************/
