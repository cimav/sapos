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
      var p     = $(this).parent();
      var o_id  = p.find('#my_cac_id').val();
      $("#img_load_"+o_id).show();

      var url   = "/objetos/borrar/"+o_id;
      var data= ""
      $.ajax({
        type:  'POST',
        url:   url,
        data:  data,
        beforeSend: function( xhr ) {
        },
        success:  function(data){
          p.remove();
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
          $("#img_load_"+o_id).hide();
        },
      });
    }
  });// live
});//document ready
