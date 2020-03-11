var model_name = 'user';

function initializeSearchForm() {
  // Do nothing
}


$(document).ready(function() {
  liveSearch();
});


$('#field_user_program_type').live("change", function(){
  showSpecificPermissions();
});

function showSpecificPermissions(){
  id   =  $('#user_id').val();
  type =  $('#field_user_program_type option:selected').val();
  url = location.pathname +"/"+ id+"/permisos/" + type;
  $.get(url, {}, function(html){
    $("#specific_permissions").html(html);
  });
}
