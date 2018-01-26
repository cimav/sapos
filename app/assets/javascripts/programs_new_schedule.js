$(document).ready(function() {
  $('#edit_program_2')
    .live("ajax:beforeSend", function(evt, xhr, status) {
    	$('#notice').html("...");
    })
    .live("ajax:success", function(evt, xhr, status) {
       parent.loadSchedule(new_schedule_term_course_group);
       parent.$("#new-schedule-dialog").dialog('close');
    })
    .live("ajax:error", function(evt, xhr, status, error) { 
        try {
          res = $.parseJSON(xhr.responseText);
        } catch(err) {
          res['errors'] = { generic_error: "Error:" + err.description };
        }

        errorMesg="";      
        $.each(res['errors_full'],function(key,value){          
          numlist = key + 1 
          if(value.search("date") > 0)
          {
            value = value.split("date")[1];
          }
          else if(value.search("staff") > 0)
          {
             value = " Debe elegir un docente";
          }
          
          errorMesg+='*'+value+'<br>';
        }); 
        
        $('#notice').html(errorMesg);
    });
});