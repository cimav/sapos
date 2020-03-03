
function start_datepicker()
{
  $.datepicker.setDefaults($.datepicker.regional["es"]);
var config = {
  changeMonth: true,
  changeYear: true,
  dateFormat: 'yy-mm-dd',
  showButtonPanel: true,
  minDate: '-5Y',
  maxDate: '+3Y',
};

$( "#committee_meeting_date" ).datepicker(config);

}
$(document).ready(function(){
    alert("xgfdg")
});