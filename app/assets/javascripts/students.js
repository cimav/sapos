var model_name = 'student';
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

$('#status').live("change", function() {
  liveSearch();
});

// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});

$('#diploma-link').live('click', function() {
  var html = $("#book-page").html();
  $("#new-advance-dialog").remove();
  $('#content-panel').append('<div title="Datos del diploma" id="new-advance-dialog">'+html+'</div>');
  $("#new-advance-dialog").dialog({ autoOpen: false, width: 450, height: 215, modal:true });
  $("#new-advance-dialog").dialog('open');

  $("#button_mine").live("click", function(){
    var libro = $("#new-advance-dialog #book").val();
    var foja  = $("#new-advance-dialog #page").val();
    var day   = $("#new-advance-dialog #print_date_3i").val();
    var month = $("#new-advance-dialog #print_date_2i").val();
    var year  = $("#new-advance-dialog #print_date_1i").val();

    var validate_book = parseInt(libro,10);
    var validate_foja = parseInt(foja,10);
 
    if(isNaN(validate_book)){
      alert("Todos los parametros deben ser numericos");
      return false;
    }

    if(isNaN(validate_foja)){
      alert("Todos los parametros deben ser numericos");
      return false;
    }

    var href  = location.pathname + "/diploma/" + $('#diploma-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja + "&day=" +day+ "&month=" + month + "&year=" + year;
    window.open(href,'newWindow');
    $("#new-advance-dialog").dialog('close');
  });
 
  return false;
});

$('#total-studies-link').live('click', function() {
 var libro = prompt("Por favor capture el libro");
 var foja  = prompt("Por favor capture la foja");
 var href  = location.pathname + "/constancia_total/" + $('#total-studies-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja;
 $('#total-studies-link').attr("target","_blank");
 $('#total-studies-link').attr("href",href);
 return true;
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

$('.assign-number')
  .live("ajax:success", function(evt, data, status, xhr) {
    var res = $.parseJSON(xhr.responseText);
    $("#flash-notice").removeClass('error').removeClass('notice').removeClass('info');
    $("#flash-notice").addClass('success').html(res['flash']['notice']);
    $("#flash-notice").slideDown().delay(1500).slideUp();
    $("#thesis-number").html(res['number']);
  })

  .live('ajax:beforeSend', function(ev, xhr, settings) {
    $("#thesis-number").html('Asignando...');
  })

  .live("ajax:error", function(data, status) {
    console.log(data);
    console.log(status);
  })

  .live('ajax:complete', function(evt, xhr, status) {

  });


$('#item-edit-form')
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    if (r['thesis_status'] == 'C') {
      $("#field_student_thesis_number").show();
    }
  });


// Schedule
$('#term_term_id').live("change", function() {
  loadStudentSchedule($('#term_term_id').val());
});

function loadStudentSchedule(term_id) {
  student_id = $('#student_id').val();
  url = location.pathname + '/' + student_id + '/horario/' + term_id;
  $.get(url, {}, function(html) {
    $("#student-schedule-area").html(html);
  });
}

// Grades
$('#grades_term_id').live("change", function() {
  loadStudentGrades($('#grades_term_id').val());
});

function loadStudentGrades(term_id) {
  student_id = $('#student_id').val();
  url = location.pathname + '/' + student_id + '/boleta/' + term_id;
  $.get(url, {}, function(html) {
    $("#student-grades-area").html(html);
  });
}

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
