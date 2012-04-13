var model_name = 'classroom';

function initializeSearchForm() {
  // Do nothing
}


$(document).ready(function() {
  liveSearch();
});

function start_datepicker()
{
	$.datepicker.setDefaults($.datepicker.regional["es"]);
  var config = {
    changeMonth: true,
    changeYear: true,
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    minDate: '-80Y',
    maxDate: '+2Y',
	};

  $( "#start_date" ).datepicker(config);
  $( "#end_date" ).datepicker(config);
}


$('#search-classroom-schedule').live("click",function(){
	url = location.pathname + '/horario/' + $('#classroom_id').val()
	
  start_date  = $('#start_date').val();
  end_date    = $('#end_date').val();

   $.get(url,{start_date: start_date, end_date: end_date},function(html){
				$('#classroom-schedule-area').html(html);
	});
});

