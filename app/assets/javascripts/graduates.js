var model_name = 'graduates';
var advprev = 0;
var schprev = 0;

$('#program_type').live("change", function() {
  modifyProgram();
  liveSearch();
});

$('#program').live("change", function() {
  liveSearch();
});

$('#campus').live("change", function() {
  liveSearch();
});

$('#supervisor').live("change", function() {
  liveSearch();
});

// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});


function initializeSearchForm() {
  $("#program_type option[value=0]").attr("selected", true);
  $("#program option[value=0]").attr("selected", true);
  $("#campus option[value=0]").attr("selected", true);
  $('#status_activos').attr('checked', true);
  $('#status_egresados').attr('checked', false);
  $('#status_bajas').attr('checked', false);
}

$('#advance-select').live("change", function() {
  $('#advance-' + advprev).hide();
  $('#advance-' + $('#advance-select').val()).show();
  advprev = $('#advance-select').val();
});

$('#scholarship-select').live("change", function() {
  $('#scholarship-' + schprev).hide();
  $('#scholarship-' + $('#scholarship-select').val()).show();
  schprev = $('#scholarship-select').val();
});

$(document).ready(function() {
  liveSearch();
});

function modifyProgram()
{
  $('#program').html("");
  var program_type = $('#program_type').val();
  var options = $('.invisible-options').find('option');
  
  $.each(options, function(i,obj){
    var obj_program_type= $(obj).attr("program_type");
    if($(obj).val()=="0"){
      $('#program').append(new Option($(obj).text(),$(obj).val()));
    }else if(obj_program_type==program_type){
      $('#program').append(new Option($(obj).text(),$(obj).val()));
    }else if(program_type=="0"){
      $('#program').append(new Option($(obj).text(),$(obj).val()));
    }
  });
}
