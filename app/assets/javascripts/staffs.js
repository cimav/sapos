var model_name = 'staff';

$.datepicker.setDefaults($.datepicker.regional["es"]);
var config = {
  changeMonth: true,
  changeYear: true,
  dateFormat: 'yy-mm-dd',
  showButtonPanel: true,
  yearRange: '1910:2040',
  minDate: '-40Y',
  maxDate: '+2Y',
};

// ** On change Program
$('#institution').live("change", function() {
  liveSearch();
});

$('#area').live("change", function() {
  liveSearch();
});

$('#staff_type').live("change", function() {
    liveSearch();
});

// ** On change Status
$('.status-cbs').live("click", function() {
  liveSearch();
});

// ** Xls
$('#to_excel').live('click', function() {
  window.location = location.pathname + "/busqueda.xls?" + $("#live-search").serialize();
});


function initializeSearchForm() {
  $("#institution option[value=0]").attr("selected", true);
  $('#status_activos').attr('checked', true);
  $('#status_inactivos').attr('checked', false);
}

$(document).ready(function(){
  liveSearch();
});

$('#item-edit-form')
  .live("ajax:beforeSend", function(evt, xhr, settings) {
    hideCurrentSeminar();
    hideCurrentMobility();	
    hideCurrentExternalCourse();
    hideCurrentLabPractice();
    hideCurrentAdmissionExam();
  })
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    loadSeminarsTable();
    loadMobilitiesTable();
    loadExternalCoursesTable();
    loadLabPracticesTable();
    loadAdmissionExamsTable();
  });


// Mobilities
var current_mobility_edit = 0;
function loadMobilitiesTable() {
   staff_id = $('#staff_id').val();
   url = location.pathname + '/' + staff_id + '/movilidad';
   $.get(url, {}, function(html) {
      $("#mobilities-area").html(html);
   });
   $("#new-mobility-dialog").remove();
   $('#content-panel').append('<div title="Nueva movilidad" id="new-mobility-dialog"><iframe width="550" height="440" src="/docentes/' + staff_id + '/nueva_movilidad" scrolling="no"></iframe></div>');
   $("#new-mobility-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
   $("#a-new-mobility").live("click", function() {
     $("#new-mobility-dialog").dialog('open');
   });
}

function hideCurrentMobility() {
  if (current_mobility_edit != 0) {
    $("#div_"+current_mobility_edit).slideUp("fast", function() {
      $('#tr_seminar_'+current_mobility_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_seminar_'+current_mobility_edit).removeClass("selected");
      });
    });
  }
}

$(".mobility-item").live("click", function() {
  staff_id = $('#staff_id').val();
  var mobility_id = $('#'+this.id).attr('mobility_id');
  var tr_mobility_id = this.id;
  if (current_mobility_edit != mobility_id) {
    if (current_mobility_edit != 0) {
      current_mobility_edit2 = current_seminar_edit;
      $("#div_"+current_mobility_edit).slideUp("fast", function() {
        $("#edit-mobility_"+current_mobility_edit2).remove();
        $('#tr_mobility_'+current_mobility_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_mobility_'+current_mobility_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + staff_id + '/movilidad/' + mobility_id;
    $("<tr class=\"edit-mobility\" id=\"edit-mobility_" + mobility_id + "\"><td colspan=\"5\"><div class=\"edit-mobility-div\" id=\"div_"+mobility_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_mobility_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+mobility_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_mobility_id).addClass("selected");
      });
    });
    current_mobility_edit = mobility_id;
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



// Seminars
var current_seminar_edit = 0;
function loadSeminarsTable() {
  staff_id = $('#staff_id').val();
  url = location.pathname + '/' + staff_id + '/seminarios';
  $.get(url, {}, function(html) {
    $("#seminars-area").html(html);
  });
  $("#new-seminar-dialog").remove();
  $('#content-panel').append('<div title="Nuevo seminario" id="new-seminar-dialog"><iframe width="550" height="440" src="/docentes/' + staff_id + '/nuevo_seminario" scrolling="no"></iframe></div>');
  $("#new-seminar-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
  $("#a-new-seminar").live("click", function() {
    $("#new-seminar-dialog").dialog('open');
  });
}

function hideCurrentSeminar() {
  if (current_seminar_edit != 0) {
    $("#div_"+current_seminar_edit).slideUp("fast", function() {
      $('#tr_seminar_'+current_seminar_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_seminar_'+current_seminar_edit).removeClass("selected");
      });
    });
  }
}

$(".seminar-item").live("click", function() {
  staff_id = $('#staff_id').val();
  var seminar_id = $('#'+this.id).attr('seminar_id');
  var tr_seminar_id = this.id;
  if (current_seminar_edit != seminar_id) {
    if (current_seminar_edit != 0) {
      current_seminar_edit2 = current_seminar_edit;
      $("#div_"+current_seminar_edit).slideUp("fast", function() {
        $("#edit-seminar_"+current_seminar_edit2).remove();
        $('#tr_seminar_'+current_seminar_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_seminar_'+current_seminar_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + staff_id + '/seminario/' + seminar_id;
    $("<tr class=\"edit-seminar\" id=\"edit-seminar_" + seminar_id + "\"><td colspan=\"5\"><div class=\"edit-seminar-div\" id=\"div_"+seminar_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_seminar_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+seminar_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_seminar_id).addClass("selected");
      });
    });
    current_seminar_edit = seminar_id;
  } else {
    $("#div_"+seminar_id).slideUp("fast", function() {
      $(".edit-seminar").remove();
      $('#'+tr_seminar_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_seminar_id).removeClass("selected");
      });
    });
    current_seminar_edit = 0;
  }
});

// External Courses
var current_external_course_edit = 0;
function loadExternalCoursesTable() {
  staff_id = $('#staff_id').val();
  url = location.pathname + '/' + staff_id + '/cursos-externos';
  $.get(url, {}, function(html) {
    $("#external-courses-area").html(html);
  });
  $("#new-external-course-dialog").remove();
  $('#content-panel').append('<div title="Nuevo curso" id="new-external-course-dialog"><iframe width="550" height="540" src="/docentes/' + staff_id + '/nuevo_curso_externo" scrolling="no"></iframe></div>');
  $("#new-external-course-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
  $("#a-new-external-course").live("click", function() {
    $("#new-external-course-dialog").dialog('open');
  });
}

function hideCurrentExternalCourse() {
  if (current_external_course_edit != 0) {
    $("#div_"+current_external_course_edit).slideUp("fast", function() {
      $('#tr_external_course_'+current_external_course_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_external_course_'+current_external_course_edit).removeClass("selected");
      });
    });
  }
}

$(".external-course-item").live("click", function() {
  staff_id = $('#staff_id').val();
  var external_course_id = $('#'+this.id).attr('external_course_id');
  var tr_external_course_id = this.id;
  if (current_external_course_edit != external_course_id) {
    if (current_external_course_edit != 0) {
      current_external_course_edit2 = current_external_course_edit;
      $("#div_"+current_external_course_edit).slideUp("fast", function() {
        $("#edit-external_course_"+current_external_course_edit2).remove();
        $('#tr_external_course_'+current_external_course_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_external_course_'+current_external_course_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + staff_id + '/curso-externo/' + external_course_id;
    $("<tr class=\"edit-external_course\" id=\"edit-external_course_" + external_course_id + "\"><td colspan=\"5\"><div class=\"edit-external_course-div\" id=\"div_"+external_course_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_external_course_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+external_course_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_external_course_id).addClass("selected");
      });
    });
    current_external_course_edit = external_course_id;
  } else {
    $("#div_"+external_course_id).slideUp("fast", function() {
      $(".edit-external_course").remove();
      $('#'+tr_external_course_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_external_course_id).removeClass("selected");
      });
    });
    current_external_course_edit = 0;
  }
});

// Lab Practices
var current_lab_practice_edit = 0;
function loadLabPracticesTable() {
  staff_id = $('#staff_id').val();
  url = location.pathname + '/' + staff_id + '/practicas-laboratorio';
  $.get(url, {}, function(html) {
    $("#lab-practices-area").html(html);
  });
  $("#new-lab-practice-dialog").remove();
  $('#content-panel').append('<div title="Nueva práctica" id="new-lab-practice-dialog"><iframe width="550" height="440" src="/docentes/' + staff_id + '/nueva_practica_laboratorio" scrolling="no"></iframe></div>');
  $("#new-lab-practice-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
  $("#a-new-lab-practice").live("click", function() {
    $("#new-lab-practice-dialog").dialog('open');
  });
}

function hideCurrentLabPractice() {
  if (current_lab_practice_edit != 0) {
    $("#div_"+current_lab_practice_edit).slideUp("fast", function() {
      $('#tr_lab_practice_'+current_lab_practice_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_lab_practice_'+current_lab_practice_edit).removeClass("selected");
      });
    });
  }
}

$(".lab-practice-item").live("click", function() {
  staff_id = $('#staff_id').val();
  var lab_practice_id = $('#'+this.id).attr('lab_practice_id');
  var tr_lab_practice_id = this.id;
  if (current_lab_practice_edit != lab_practice_id) {
    if (current_lab_practice_edit != 0) {
      current_lab_practice_edit2 = current_lab_practice_edit;
      $("#div_"+current_lab_practice_edit).slideUp("fast", function() {
        $("#edit-lab_practice_"+current_lab_practice_edit2).remove();
        $('#tr_lab_practice_'+current_lab_practice_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_lab_practice_'+current_lab_practice_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + staff_id + '/practica-laboratorio/' + lab_practice_id;
    $("<tr class=\"edit-lab_practice\" id=\"edit-lab_practice_" + lab_practice_id + "\"><td colspan=\"5\"><div class=\"edit-lab_practice-div\" id=\"div_"+lab_practice_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_lab_practice_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+lab_practice_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_lab_practice_id).addClass("selected");
      });
    });
    current_lab_practice_edit = lab_practice_id;
  } else {
    $("#div_"+lab_practice_id).slideUp("fast", function() {
      $(".edit-lab_practice").remove();
      $('#'+tr_lab_practice_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_lab_practice_id).removeClass("selected");
      });
    });
    current_lab_practice_edit = 0;
  }
});

$('#search-staff-schedule').live("click",function(){
	url = location.pathname + '/horario/' + $('#staff_id').val()

	start_date  = $('#start_date').val();
  end_date    = $('#end_date').val();

   $.get(url,{ start_date: start_date, end_date: end_date},function(html){
				$('#staff-schedule-area').html(html);
	});
});

function start_datepicker()
{
  $( "#start_date" ).datepicker(config);
  $( "#end_date" ).datepicker(config);

  console.log("Cool1");
}

$('.delete-file')
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    var s_id = r.seminar_id;
    $("#tr_seminar_"+s_id).hide();
  });

$('.delete-file')
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    var s_id = r.seminar_id;
    $("#tr_seminar_"+s_id).hide();
  });

$('.delete-file-ec')
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    var s_id = r.external_course_id;
    $("#tr_external_course_"+s_id).hide();
  });

$('.delete-file-lp')
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    var s_id = r.lab_practice_id;
    $("#tr_lab_practice_"+s_id).hide();
  });


// Exámenes de admisión
var current_admission_exam_edit = 0;
function loadAdmissionExamsTable() {
    staff_id = $('#staff_id').val();
    url = location.pathname + '/' + staff_id + '/examenes_admision';
    $.get(url, {}, function(html) {
        $("#admission-exams-area").html(html);
    });
    $("#new-admission_exam-dialog").remove();
    $('#content-panel').append('<div title="Nuevo examen de admisión" id="new-admission_exam-dialog"><iframe width="550" height="540" src="/docentes/' + staff_id + '/nuevo_examen_admision" scrolling="no"></iframe></div>');
    $("#new-admission_exam-dialog").dialog({ autoOpen: false, width: 640, height: 550, modal:true });
    $("#a-new-admission-exam").live("click", function() {
        $("#new-admission_exam-dialog").dialog('open');
    });
}

function hideCurrentAdmissionExam() {
    if (current_admission_exam_edit != 0) {
        $("#div_"+current_admission_exam_edit).slideUp("fast", function() {
            $('#tr_admission_exam_'+current_admission_exam_edit).animate({ backgroundColor: "white" }, 1000, function() {
                $('#tr_admission_exam_'+current_admission_exam_edit).removeClass("selected");
            });
        });
    }
}

$(".admission-exam-item").live("click", function() {
    staff_id = $('#staff_id').val();
    var admission_exam_id = $('#'+this.id).attr('admission_exam_id');
    var tr_admission_exam_id = this.id;
    if (current_admission_exam_edit != admission_exam_id) {
        if (current_admission_exam_edit != 0) {
            current_admission_exam_edit2 = current_admission_exam_edit;
            $("#div_"+current_admission_exam_edit).slideUp("fast", function() {
                $("#edit-admission_exam_"+current_admission_exam_edit2).remove();
                $('#tr_admission_exam_'+current_admission_exam_edit2).animate({ backgroundColor: "white" }, 1000, function() {
                    $('#tr_admission_exam_'+current_admission_exam_edit2).removeClass("selected");
                });
            });
        }

        url = location.pathname + '/' + staff_id + '/examen_admision/' + admission_exam_id;
        $("<tr class=\"edit-admission_exam_\" id=\"edit-admission_exam_" + admission_exam_id + "\"><td colspan=\"5\"><div class=\"edit-admission_exam_-div\" id=\"div_"+admission_exam_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
        $.get(url, {}, function(html) {
            $('#'+tr_admission_exam_id).animate({ backgroundColor: "#dddddd" }, 1000);
            $("#div_"+admission_exam_id).hide().html(html).slideDown("fast", function() {
                $('#'+tr_admission_exam_id).addClass("selected");
            });
        });
        current_admission_exam_edit = admission_exam_id;
    } else {
        $("#div_"+admission_exam_id).slideUp("fast", function() {
            $(".edit-admission_exam").remove();
            $('#'+tr_admission_exam_id).animate({ backgroundColor: "white" }, 1000, function() {
                $('#'+tr_admission_exam_id).removeClass("selected");
            });
        });
        current_admission_exam_edit = 0;
    }
});
