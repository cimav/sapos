$(document).ready(function() {
  liveSearch();

  $("#advance_student_id").live("change", function(){
    $("#advance-data").html("Cargando...")
    var form = $("#item-new-form");
    var url = location.pathname + "/advance_data";
    var formData = form.serialize();
    $.get(url, formData, function(html) {
      $("#advance-data").html(html)
    });
  });
});
