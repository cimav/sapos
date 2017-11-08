var model_name   = 'student';
var advprev      = 0;
var schprev      = 0;
var config_click = false;

if(!getCookie("accents")){
  document.cookie="accents=0";
}

if(!getCookie("the_first")){
  document.cookie="the_first=0";
}

$('#program_type').live("change", function() {
  modifyProgram();
  liveSearch({json: true});
});

$('#program').live("change", function() {
  liveSearch({json: true});
});

$('#campus').live("change", function() {
  liveSearch({json: true});
});

$('#supervisor').live("change", function() {
  liveSearch({json: true});
});

$('#status').live("change", function() {
  liveSearch({json: true});
});

$('#scholarship_type').live("change", function() {
    liveSearch({json: true});
});

$('#student_time').live("change", function() {
    liveSearch({json: true});
});

$('#order_by').live("change", function() {
    liveSearch({json: true});
});

$('#genero').live("change", function() {
  $("#items-list").html("<img src=\"\/images\/ajax-load2.gif\">");
  
  valor = $(this).val();
  h = {"command": null, "data": null};
  if(valor!=0){h = {"command": "gender", "data": valor}}
  
  searchByCommand(h);  
  setItems(items);
});

$('.div-config').live({
    mouseenter: function(){
      $("#search-config").css("visibility","visible");
    },
    mouseleave: function(){
      if(!config_click){
        $("#search-config").css("visibility","hidden");
      }
    }
  });

$("#search-config").live("click",function(){
  if(!config_click){
    config_click = true;
    $("#search-config").css("visibility","visible");
    $(".config-menu").show("fast");
  }
  else{
    config_click = false;
    $(".config-menu").hide("fast");
  }
});


// ** Xls
$('#to_excel').live('click', function() {
  url = location.pathname + "/set/xls";
  var order_by = $("#order_by").val();
  data = "items="+items_found+"order_by="+order_by
  $.post(url,data)
    .done(function(data){
      url = location.pathname + "/get/xls/"+data;
      $("#downloads_iframe").attr("src",url);
    })
    .fail(function(data){
      alert("Hubo un error en la generacion del xls");
    });
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
      return false;}

    if(isNaN(validate_foja)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    var href  = location.pathname + "/diploma/" + $('#diploma-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja + "&day=" +day+ "&month=" + month + "&year=" + year;
    window.open(href,'newWindow');
    $("#new-advance-dialog").dialog('close');
  });
 
  return false;
});

$('#total-studies-link').live('click', function() {
  var html = $("#book-page").html();
  $("#new-advance-dialog").remove();
  $('#content-panel').append('<div title="Datos del certificado de estudios" id="new-advance-dialog">'+html+'</div>');
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
      return false;}

    if(isNaN(validate_foja)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    var href  = location.pathname + "/constancia_total/" + $('#diploma-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja + "&day=" +day+ "&month=" + month + "&year=" + year;
    window.open(href,'newWindow');
    $("#new-advance-dialog").dialog('close');
  });
 
  return false;
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
  $(".adv-div").hide();
  var mval = $(this).val();
  $("#advance-"+mval).show();
});

$('#scholarship-select').live("change", function() {
  $('#scholarship-' + schprev).hide();
  $('#scholarship-' + $('#scholarship-select').val()).show();
  schprev = $('#scholarship-select').val();
});

$(document).ready(function() {
  liveSearch({json: true});

  if(!isNaN(parseInt(remote_id,10))){
    $("#searchy").val(remote_id);
    setTimeout(function(){
      var e = jQuery.Event("keyup");
      search(e);
      $("#items-list li:first").addClass("selected");
      $("#items-list li:first a").click();
    }, 1000);
  }

  $("#accent_check").live("click",function(){
    if(getCookie("accents")==1){
      document.cookie="accents=0";
    }
    else if(getCookie("accents")==0){
      document.cookie="accents=1";
    }
  });

  $("#first_check").live("click",function(){
    if(getCookie("the_first")==1){
      document.cookie="the_first=0";
    }
    else if(getCookie("the_first")==0){
      document.cookie="the_first=1";
    }
  });

  if(getCookie("accents")==1){
    $("#accent_check").prop("checked",true);
  }
  else if(getCookie("accents")==0){
    $("#accent_check").prop("checked",false);
  }

  if(getCookie("the_first")==1){
    $("#first_check").prop("checked",true);
  }
  else if(getCookie("the_first")==0){
    $("#first_check").prop("checked",false);
  }
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

