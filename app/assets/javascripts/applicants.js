var model_name = 'applicant';
var advprev = 0;
var schprev = 0;

$('#program').live("change", function() {
  liveSearch();
});

$('#status').live("change", function() {
  liveSearch();
});

// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});

$(document).ready(function() {
  liveSearch();
});
