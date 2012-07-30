$(document).ready(function(){
  loadLogs();
});

// Load Log

function loadLogs()
{
  url = location.pathname + 'logs/show';
  $.get(url, {}, function(html) {
    $("#logs-area").html(html);
  });

  url = location.pathname + 'estudiantes/avances';
  $.get(url, {}, function(html) {
    $("#advances-area").html(html);
  });
}
