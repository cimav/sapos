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

// ** On change Area
$('#area_s').live("change", function() {
   liveSearch({json: true});
});

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
    liveSearch({json: true});
});

$('#year').live("change", function() {
    liveSearch({json: true});
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

$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});

$('#actives_to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?utf8=%E2%9C%93&program_type=0&program=0&campus=0&supervisor=0&status=todos_activos&scholarship_type=10&student_time=10&genero=0&order_by=last_name"
});

$('#diploma-link').live('click', function() {
  var html = $("#book-page").html();
  $("#new-advance-dialog").remove();
  $('#content-panel').append('<div title="Datos del diploma" id="new-advance-dialog">'+html+'</div>');
  $("#new-advance-dialog").dialog({ autoOpen: false, width: 500, height: 215, modal:true });
  $("#new-advance-dialog").dialog('open');

  $("#button_mine").live("click", function(){
    var libro = $("#new-advance-dialog #book").val();
    var foja  = $("#new-advance-dialog #page").val();
    var day   = $("#new-advance-dialog #print_date_3i").val();
    var month = $("#new-advance-dialog #print_date_2i").val();
    var year  = $("#new-advance-dialog #print_date_1i").val();
    var duplicate  = $("#new-advance-dialog #duplicate:checked").length;

    var validate_book = parseInt(libro,10);
    var validate_foja = parseInt(foja,10);
 
    if(isNaN(validate_book)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    if(isNaN(validate_foja)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    var href  = location.pathname + "/diploma/" + $('#diploma-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja + "&day=" +day+ "&month=" + month + "&year=" + year + "&duplicate=" + duplicate;
    window.open(href,'newWindow');
    $("#new-advance-dialog").dialog('close');
  });
 
  return false;
});

$('#total-studies-link').live('click', function() {
  var html = $("#book-page").html();
  $("#new-advance-dialog").remove();
  $('#content-panel').append('<div title="Datos del certificado de estudios" id="new-advance-dialog">'+html+'</div>');
  $("#new-advance-dialog").dialog({ autoOpen: false, width: 450, height: 230, modal:true });
  $("#new-advance-dialog").dialog('open');

  $("#button_mine").live("click", function(){
    var libro      = $("#new-advance-dialog #book").val();
    var foja       = $("#new-advance-dialog #page").val();
    var duplicate  = $("#new-advance-dialog #duplicate:checked").length;
    var day        = $("#new-advance-dialog #print_date_3i").val();
    var month      = $("#new-advance-dialog #print_date_2i").val();
    var year       = $("#new-advance-dialog #print_date_1i").val();
    var validate_book = parseInt(libro,10);
    var validate_foja = parseInt(foja,10);
 
    if(isNaN(validate_book)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    if(isNaN(validate_foja)){
      alert("Todos los parametros deben ser numericos");
      return false;}

    var href  = location.pathname + "/constancia_total/" + $('#diploma-link').attr("thesis_id") + "/?libro=" + libro + "&foja=" + foja + "&day=" +day+ "&month=" + month + "&year=" + year + "&duplicate=" + duplicate;
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
  .live("ajax:beforeSend", function(evt, xhr, settings) {
    hideCurrentStudentMobility(); 
  })
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    if (r['thesis_status'] == 'C') {
      $("#field_student_thesis_number").show();
    }
    loadStudentMobilitiesTable();
  });

// StudentMobilities
var current_student_mobility_edit = 0;
function loadStudentMobilitiesTable() {
   student_id = $('#student_id').val();
   url = location.pathname + '/' + student_id + '/movilidad';
   $.get(url, {}, function(html) {
      $("#mobilities-area").html(html);
   });
   $("#new-mobility-dialog").remove();
   $('#content-panel').append('<div title="Nueva movilidad" id="new-mobility-dialog"><iframe width="550" height="440" src="/estudiantes/' + student_id + '/nueva_movilidad" scrolling="no"></iframe></div>');
   $("#new-mobility-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
   $("#a-new-mobility").live("click", function() {
     $("#new-mobility-dialog").dialog('open');
   });
}

function hideCurrentStudentMobility() {
  if (current_student_mobility_edit != 0) {
    $("#div_"+current_student_mobility_edit).slideUp("fast", function() {
      $('#tr_mobility_'+current_student_mobility_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_mobility_'+current_student_mobility_edit).removeClass("selected");
      });
    });
  }
}

$(".mobility-item").live("click", function() {
  student_id = $('#student_id').val();
  var mobility_id = $('#'+this.id).attr('student_mobility_id');
  var tr_mobility_id = this.id;
  if (current_student_mobility_edit != mobility_id) {
    if (current_student_mobility_edit != 0) {
      current_student_mobility_edit2 = current_student_mobility_edit;
      $("#div_"+current_student_mobility_edit).slideUp("fast", function() {
        $("#edit-mobility_"+current_student_mobility_edit2).remove();
        $('#tr_mobility_'+current_student_mobility_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_mobility_'+current_student_mobility_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + student_id + '/movilidad/' + mobility_id;
    $("<tr class=\"edit-mobility\" id=\"edit-mobility_" + mobility_id + "\"><td colspan=\"5\"><div class=\"edit-mobility-div\" id=\"div_"+mobility_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_mobility_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+mobility_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_mobility_id).addClass("selected");
      });
    });
    current_student_mobility_edit = mobility_id;
  } else {
    $("#div_"+mobility_id).slideUp("fast", function() {
      $(".edit-mobility").remove();
      $('#'+tr_mobility_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_mobility_id).removeClass("selected");
      });
    });
    current_mobility_edit = 0;
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


$("#a-id-card").live("click", function(e){
  chk = $("#chk_extension").prop("checked");
  s_id = $("#student_id").val();

  if(chk==true){
    html = $("#extension-page").html();
    $("#new-advance-dialog").remove();
    $('#content-panel').append('<div title="Fecha" id="new-advance-dialog">'+html+'</div>');
    $("#new-advance-dialog").dialog({ autoOpen: false, width: 500, height: 280, modal:true });
    $("#new-advance-dialog").dialog('open');
  }else{
    url = '/estudiantes/'+s_id+'/credencial.pdf';
    location.pathname = url;
  }

  $("#button_mine").live("click", function(){
    s_id = $("#student_id").val();

    var notas = $("#new-advance-dialog textarea#notes").val();
    var day   = $("#new-advance-dialog #print_date_3i").val();
    var month = $("#new-advance-dialog #print_date_2i").val();
    var year  = $("#new-advance-dialog #print_date_1i").val();

    var data = 'day=' +day+ '&month=' + month + '&year=' + year +'&notes=' + notas;
    var url = location.pathname + '/' + s_id + '/1/credencial.pdf'

    location.href = url+'?'+data;
    /*$.post(url,data)
      .done(function(data){
        $("#downloads_iframe").attr("src",url);
      })
      .fail(function(data){
        alert("Hubo un error en la generacion de la credencial");
      });*/

    $("#new-advance-dialog").dialog('close');
  });

  return false;
})



