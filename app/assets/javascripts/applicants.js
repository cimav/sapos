var model_name = 'applicant';
var advprev = 0;
var schprev = 0;

$('#program').live("change", function() {
  liveSearch();
});

$('#status').live("change", function() {
  var str = $(this).val();
  if(str=="4")
  {
    $('#status_borrados').attr('checked', true);
  }
  liveSearch();
});

$('#campus').live("change", function() {
  liveSearch();
});

// ** On change Status
$('.status-cbs').live("click", function() {
  liveSearch();
});

// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});

$(document).ready(function() {
  liveSearch();
  
  $("#applicant_status").live("change", function(){
     var str = $(this).val();
     if(str=="4")
     {
       alert("Debes escribir una explicación del borrado en las notas");
     }
  });

  $('#item-edit-form').live('ajax:success', function(evt, data, status, xhr) {
      var r = $.parseJSON(xhr.responseText);

      if(r['params']['student_id'])
      {
         var student_id =r['params']['student_id'];
         window.location="/estudiantes/?student_id="+student_id;
      }

      if(r['params']['folio'])
      {
        folio = r['params']['folio'];
        $("#folio_div").html("Folio: "+ folio);
      }
  });

  $('#status_formato_ingreso').live("change",function(){
    var checked = $(this).attr("checked");

    if(checked){
      if(confirm("¿Esta seguro que desea activar el formato de ingreso?"))
      {
        activate(1);
        alert("Formato Activado");
      }
      else
      {
        $(this).attr("checked",false);
      }
    }
    else
    {
      if(confirm("¿Esta seguro que desea desactivar el formato de ingreso?"))
      {
        activate(0);
        alert("Desactivado");
      }
      else
      {
        $(this).attr("checked",true);
      }
    }
  });

});

function activate(opt) {
  var uri   = '/usuarios/0/config/1';
  var data  = 'value='+opt ;
  $.ajax({
    type: 'POST',
    url:   uri,
    data:  data,
    success:  function(data){
      var jq   = jQuery.parseJSON(data);
      try{
      }
      catch(e)
      {
       // let it pass
      }
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
         alert(jq.flash.error);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
  });
}

function initializeSearchForm() {
  $("#program option[value=0]").attr("selected", true);
  $("#status option[value=0]").attr("selected", true);
}

