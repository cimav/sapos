var model_name = 'area';

$(document).ready(function() {
  liveSearch();

  $('#area_type').live("change", function() {
    liveSearch();
  });
});

function initializeSearchForm() {
  $('#area_type').val();
}
