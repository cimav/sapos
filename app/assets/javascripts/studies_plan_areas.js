var model_name = 'studies_plan_area';

$(document).ready(function() {
  liveSearch();

  $("#program_field").live("change",function(){
    $("#studies_plan_area_studies_plan_id option[value!='']").hide();
    $("#studies_plan_area_studies_plan_id option[program_id="+$(this).val()+"]").show();
    $("#field_area_area_type").show();
  });
});

function initializeSearchForm() {
  $('#program_field').val();
}
