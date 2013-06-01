var model_name = 'applicant';
var advprev = 0;
var schprev = 0;

$('#program').live("change", function() {
  liveSearch();
});

$('#status').live("change", function() {
  liveSearch();
});

$('#campus').live("change", function() {
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
});

function initializeSearchForm() {
  $("#program option[value=0]").attr("selected", true);
  $("#status option[value=0]").attr("selected", true);
}

