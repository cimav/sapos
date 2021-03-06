var model_name = 'applicant';
$(document).ready(function() {
  $("#application_button").live("click",function(){
    $('#cancel_button').hide();
    var app_id = $("#internship_id").val();
    window.location="/internados/aspirantes/finalizar/"+app_id;
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
 
 $("#finalize_button").live("click",function(){
   var i_id      = $('#internship_id').val();
   var token     = $('#itoken').val();
   var data      = ""
   var url       = "/internados/aspirantes/registro/finalizar/"+token+"/"+i_id;
   
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
        
        //alert("Mensaje Enviado");
        /*alert("success")*/      
        if (data.internship_type_id==11)
        {
          $('.terms-groups').show();

         
        }else
        {
          $('.terms').show();
        }
        
        $('.header').hide();
        $('.recomm').hide();
        $('.fields_requested').hide();
        $(this).hide();
      },
      error: function(xhr, textStatus, error){
         var text = xhr.responseText;
         try{
           var jq   = jQuery.parseJSON(xhr.responseText);
           alert(jq.flash.errors);
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
