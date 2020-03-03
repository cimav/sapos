$(document).ready(function(){
  loadLogs();
  $(".show-details").live("click",function(){
    d = $(this).parent().parent().find(".details")//.find(".details");
    $(d).toggle("fast");
    //data =$(d).html();
  });


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
