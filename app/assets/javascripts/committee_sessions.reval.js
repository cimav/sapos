var model_name = 'committee_agreement_object'

$(document).ready(function() {
  $('#item-new-form').live('ajax:complete', function(evt, xhr, status) {
        if(status=="error"){
          // No hacemos nada
        }else{
          var res    = $.parseJSON(xhr.responseText);
          if(res['uniq']!=0){
            location.reload();
          }
        }
  });


  $(".delete-agreement-course").live({
    mouseover: function(){
      $(this).css({ opacity: 1.0 })
    },
    mouseout: function(){
      $(this).css({ opacity: 0.3 });
    },
    click: function(){
      $("#img_load").show();
 /*     var p     = $(this).parent();
      var a_id  = p.parent().parent().find("#my_id").val();
      var valor = p.find("#my_sinodal_id").val();
      var tipo  = p.find("#my_sinodal_type_id").val();
      var url   = "/comite/acuerdos/persona/borrar/"+valor;
      var data= ""
      $.ajax({
        type:  'POST',
        url:   url,
        data:  data,
        beforeSend: function( xhr ) {
        },
        success:  function(data){
          p.remove();
          if(tipo==3){
            $("#agreement_aux_"+a_id).append(new Option("Titular",3));
            $("#agreement_aux_"+a_id).select2().val(3).trigger("change");
          }
        },
        error: function(xhr, textStatus, error){
           var text = xhr.responseText;
           try{
             var jq   = jQuery.parseJSON(xhr.responseText);
           }
           catch(e){
             alert("Error desconocido: "+e.message)
           }
        },
        complete: function(){
          $("#img_load").hide();
        },
      });*/
    }
  });// live
});//document ready
