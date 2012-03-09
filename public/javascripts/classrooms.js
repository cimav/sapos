var model_name = 'classroom';

function initializeSearchForm() {
  // Do nothing
}


$(document).ready(function() {
  liveSearch();
});


$('#search-classroom-schedule').live("click",function(){
	url = location.pathname + '/horario/' + $('#classroom_id').val()
	var start_day 	= $('#start_date_start_year1994_3i').val();
	var start_month = $('#start_date_start_year1994_2i').val();
	var start_year	= $('#start_date_start_year1994_1i').val();
	var end_day 	= $('#end_date_start_year1994_3i').val();
	var end_month = $('#end_date_start_year1994_2i').val();
	var end_year	= $('#end_date_start_year1994_1i').val();

	var errors = 0;
	if(end_year<start_year)
	{
			errors++;
	}
	
	if(end_year==start_year)
	{
		if(end_month<start_month)
		{
			errors++;
		}
		
		if(end_month==start_month)
		{
			if(end_day<start_day)
			{
				errors++;
			}
		}
	}
	
	if(errors>0)
	{
		alert("La fecha de inicio no puede ser menor a la fecha de término");
		return false;
	}

   $.get(url,{ start_day: start_day, start_month: start_month, start_year: start_year, end_day: end_day, end_month: end_month, end_year: end_year},function(html){
				$('#classroom-schedule-area').html(html);
	});
});

