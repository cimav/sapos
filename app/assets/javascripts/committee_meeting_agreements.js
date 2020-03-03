var selected_meeting_id;
$('#sesion').live("change", function() {
    selected_meeting_id = $(this).val();
    $('#selected_meeting').val(selected_meeting_id);
    liveSearch();

});
$(document).ready(function() {
    selected_meeting_id = $('#sesion').val();
    $('#selected_meeting').val(selected_meeting_id);
    liveSearch();
    });
