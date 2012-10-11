var model_name = 'program';
var current_option = 'students';
function initializeSearchForm() {
  // Do nothing
}

$('#program_type').live("change", function() {
  liveSearch();
});

function initializeSearchForm() {
  $("#program_type option[value=0]").attr("selected", true);
}


$(document).ready(function() {
  liveSearch();
});

$('#item-edit-form')
  .live("ajax:beforeSend", function(evt, xhr, settings) {
    hideCurrentCourse();
    hideCurrentTerm();
  })
  .live('ajax:success', function(evt, data, status, xhr) {
    var r = $.parseJSON(xhr.responseText);
    loadPlanTable();
    loadTermsTable();
  });

// Plan
var current_plan_edit = 0;
function loadPlanTable() {
  program_id = $('#program_id').val();
  url = location.pathname + '/' + program_id + '/plan';
  $.get(url, {}, function(html) {
    $("#plan-area").html(html);
    loadCoursesDropdown();
  });
  $("#new-course-dialog").remove();
  $('#content-panel').append('<div title="Nuevo curso" id="new-course-dialog"><iframe width="550" height="340" src="/programas/' + program_id + '/nuevo_curso" scrolling="no"></iframe></div>');
  $("#new-course-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
  $("#a-new-course").live("click", function() {
    $("#new-course-dialog").dialog('open');
  });
}

function hideCurrentCourse() {
  if (current_plan_edit != 0) {
    $("#div_"+current_plan_edit).slideUp("fast", function() {
      $('#tr_'+current_plan_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_'+current_plan_edit).removeClass("selected");
      });
    });
  }
}

$(".course").live("click", function() {
  program_id = $('#program_id').val();
  var course_id = $('#'+this.id).attr('course_id');
  var tr_id = this.id;
  if (current_plan_edit != course_id) {
    if (current_plan_edit != 0) {
      current_plan_edit2 = current_plan_edit;
      $("#div_"+current_plan_edit).slideUp("fast", function() {
        $("#edit-course_"+current_plan_edit2).remove();
        $('#tr_'+current_plan_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_'+current_plan_edit2).removeClass("selected");
        });
      });
    }
    url = location.pathname + '/' + program_id + '/curso/' + course_id;
    $("<tr class=\"edit-course\" id=\"edit-course_" + course_id + "\"><td colspan=\"5\"><div class=\"edit-course-div\" id=\"div_"+course_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+course_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_id).addClass("selected");
      });
    });
    current_plan_edit = course_id;
  } else {
    $("#div_"+course_id).slideUp("fast", function() {
      $(".edit-course").remove();
      $('#'+tr_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_id).removeClass("selected");
      });
    });
    current_plan_edit = 0;
  }
});


// Terms
var current_term_edit = 0;
function loadTermsTable() {
  program_id = $('#program_id').val();
  url = location.pathname + '/' + program_id + '/periodos';
  $.get(url, {}, function(html) {
    $("#terms-area").html(html);
    loadTermsDropdown();
  });
  $("#new-term-dialog").remove();
  $('#content-panel').append('<div title="Nuevo periodo" id="new-term-dialog"><iframe width="550" height="340" src="/programas/' + program_id + '/nuevo_periodo" scrolling="no"></iframe></div>');
  $("#new-term-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
  $("#a-new-term").live("click", function() {
    $("#new-term-dialog").dialog('open');
  });
}

function hideCurrentTerm() {
  if (current_term_edit != 0) {
    $("#div_"+current_term_edit).slideUp("fast", function() {
      $('#tr_term_'+current_term_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_term_'+current_term_edit).removeClass("selected");
      });
    });
  }
}

$(".term-item").live("click", function() {
  program_id = $('#program_id').val();
  var term_id = $('#'+this.id).attr('term_id');
  var tr_term_id = this.id;
  if (current_term_edit != term_id) {
    if (current_term_edit != 0) {
      current_term_edit2 = current_term_edit;
      $("#div_"+current_term_edit).slideUp("fast", function() {
        $("#edit-course_"+current_term_edit2).remove();
        $('#tr_term_'+current_term_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_term_'+current_term_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + program_id + '/periodo/' + term_id;
    $("<tr class=\"edit-course\" id=\"edit-course_" + term_id + "\"><td colspan=\"5\"><div class=\"edit-course-div\" id=\"div_"+term_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_term_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+term_id).hide().html(html).slideDown("fast", function() {
        $('#'+tr_term_id).addClass("selected");
      });
    });
    current_term_edit = term_id;
  } else {
    $("#div_"+term_id).slideUp("fast", function() {
      $(".edit-course").remove();
      $('#'+tr_term_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_term_id).removeClass("selected");
      });
    });
    current_term_edit = 0;
  }
});


// Schedule
var current_schedule_edit = 0;
function loadSchedule(g) {
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();
  if (null === g) g = '';
  if ((term_id > 0) && (course_id > 0)) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/horario/" + g;
    $.get(url, {}, function(html) {
      $("#program-area").html(html);
    });
    $("#new-schedule-dialog").remove();
    url_dialog = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/nueva_sesion/" + g;
    $('#content-panel').append('<div title="Agregar sesión" id="new-schedule-dialog"><iframe width="550" height="340" src="' + url_dialog + '" scrolling="no"></iframe></div>');
    $("#new-schedule-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
    $("#a-new-schedule").live("click", function() {
      $("#new-schedule-dialog").dialog('open');
    });
  } else {
      $("#program-area").html('');
  }
}

function hideCurrentSchedule() {
  if (current_schedule_edit != 0) {
    $("#div_"+current_schedule_edit).slideUp("fast", function() {
      $('#tr_schedule_'+current_schedule_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_schedule_'+current_schedule_edit).removeClass("selected");
      });
    });
  }
}

$(".schedule-item").live("click", function() {
  program_id = $('#program_id').val();
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  var schedule_id = $('#'+this.id).attr('schedule_id');
  var tr_schedule_id = this.id;
  if (current_schedule_edit != schedule_id) {
    if (current_schedule_edit != 0) {
      current_schedule_edit2 = current_schedule_edit;
      $("#div_"+current_schedule_edit).slideUp("fast", function() {
        $("#edit-schedule_"+current_schedule_edit2).remove();
        $('#tr_schedule_'+current_schedule_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_schedule_'+current_schedule_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + program_id + '/periodo/' + term_id + '/curso/' + course_id + '/sesion/' + schedule_id;
    $("<tr class=\"edit-schedule edit-subitem\" id=\"edit-schedule_" + schedule_id + "\"><td colspan=\"6\"><div class=\"edit-course-div\" id=\"div_"+schedule_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $('#'+tr_schedule_id).animate({ backgroundColor: "#dddddd" }, 1000);
    $('<iframe />', {
      id: 'edit-schedule-iframe' + schedule_id,
      src: url,
      scrolling: 'no',
      onload: "autoResizeIFRAME('edit-schedule-iframe" + schedule_id + "')"
    }).appendTo("#div_"+schedule_id);

    $("#div_"+schedule_id).slideDown("fast", function() {
      $('#'+tr_schedule_id).addClass("selected");
    });

    current_schedule_edit = schedule_id;
  } else {
    $("#div_"+schedule_id).slideUp("fast", function() {
      $(".edit-course").remove();
      $('#'+tr_schedule_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_schedule_id).removeClass("selected");
      });
    });
    current_schedule_edit = 0;
  }
});

// Students
function loadStudents(g) {
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();
  if (null === g) g = '';
  if ((term_id > 0) && (course_id > 0)) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/estudiantes/" + g;
    $.get(url, {}, function(html) {
      $("#program-area").html(html);
    });
    $("#add-student-to-course-dialog").remove();
    url_dialog = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/agregar_estudiante/" + g;
    $('#content-panel').append('<div title="Agregar estudiante a curso" id="add-student-to-course-dialog"><iframe width="550" height="340" src="' + url_dialog + '" scrolling="no"></iframe></div>');
    $("#add-student-to-course-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
    $("#add-student-to-course").live("click", function() {
      $("#add-student-to-course-dialog").dialog('open');
    });
  } else {
      $("#program-area").html('');
  }
}

var current_tc_student_edit = 0;
$(".tc-students-item").live("click", function() {
  program_id = $('#program_id').val();
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  var tc_student_id = $('#'+this.id).attr('tc_student_id');
  var tr_tc_student_id = this.id;
  if (current_tc_student_edit != tc_student_id) {
    if (current_tc_student_edit != 0) {
      current_tc_student_edit2 = current_tc_student_edit;
      $("#div_"+current_tc_student_edit).slideUp("fast", function() {
        $("#edit-course_"+current_tc_student_edit2).remove();
        $('#tr_tc_student_'+current_tc_student_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_tc_student_'+current_tc_student_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + program_id + '/periodo/' + term_id + '/curso/' + course_id + '/estudiante/' + tc_student_id;
    $("<tr class=\"edit-subitem edit-student\" id=\"edit-course_" + tc_student_id + "\"><td colspan=\"6\"><div class=\"edit-course-div\" id=\"div_"+tc_student_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_tc_student_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+tc_student_id).hide();
      $('<iframe />', {
        id: 'edit-student-iframe' + tc_student_id,
        src: url,
        scrolling: 'no',
        onload: "autoResizeIFRAME('edit-schedule-iframe" + tc_student_id + "')"
      }).appendTo("#div_"+tc_student_id);

      $("#div_"+tc_student_id).slideDown("fast", function() {
        $('#'+tr_tc_student_id).addClass("selected");
      });
    });
    current_tc_student_edit = tc_student_id;
  } else {
    $("#div_"+tc_student_id).slideUp("fast", function() {
      $(".edit-student").remove();
      $('#'+tr_tc_student_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_tc_student_id).removeClass("selected");
      });
    });
    current_tc_student_edit = 0;
  }
});

// Program
$('#tc_term_id').live("change", function() {
  loadCoursesDropdown();
});

function loadTermsDropdown() {
  program_id = $('#program_id').val();
  url = location.pathname + "/" + program_id + "/terms_dropdown";
  $.get(url, {}, function(html) {
    $("#terms-dropdown").html(html);
    $("#courses-dropdown").html('<span>Es necesario seleccionar un periodo</span>');
    $("#program-area").html('');
  });
}


function loadCoursesDropdown() {
  term_id = $('#tc_term_id').val();
  program_id = $('#program_id').val();
  $("#program-area").html('');
  if (term_id > 0) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/courses_dropdown";
    $.get(url, {}, function(html) {
      $("#courses-dropdown").html(html);
    });
  } else {
      $("#courses-dropdown").html('<span>Es necesario seleccionar un periodo</span>');
  }
}

$('#tc_course_id').live("change", function() {
  if ($('#tc_course_id').val() == 0) {
    openAssignCoursesDialog();
  } else {
    loadStudents(null);
  }
});
    
function openAssignCoursesDialog() {
  $("#program-area").html('');
  program_id = $('#program_id').val();
  term_id = $('#tc_term_id').val();
  $("#select-courses-dialog").remove();
  url = '/programas/' + program_id + '/periodo/' + term_id + '/seleccionar_cursos';
  $('#content-panel').append('<div title="Asignar cursos" id="select-courses-dialog"><iframe width="550" height="440" src="' + url + '" scrolling="no"></iframe></div>');
  $("#select-courses-dialog").dialog({ autoOpen: true, width: 590, height: 550, modal:true });
}

$('#a-tc-schedule').live('click', function() {
  loadSchedule($('#tc_group').val());
  current_option = 'schedule';
});

$('#a-tc-students').live('click', function() {
  loadStudents($('#tc_group').val());
  current_option = 'students';
});

$('#a-tc-attendee').live('click', function() {
  loadAttendee($('#tc_group').val());
  current_option = 'attendee';
});

$('#a-tc-documentation').live('click', function() {
  loadDocumentation($('#tc_group').val());
  current_option = 'documentation';
});

// Enrollment
$('#enrollment_term_id').live("change", function() {
  loadEnrollment();
});

function loadEnrollment() {
  term_id = $('#enrollment_term_id').val();
  program_id = $('#program_id').val();
  if (term_id > 0) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/inscripciones";
    $.get(url, {}, function(html) {
      $("#enrollment-area").html(html);
    });

    $("#new-enrollment-dialog").remove();
    url_dialog = location.pathname + "/" + program_id + "/periodo/" + term_id + "/nueva_inscripcion";
    $('#content-panel').append('<div title="Inscribir estudiante" id="new-enrollment-dialog"><iframe width="550" height="340" src="' + url_dialog + '" scrolling="no"></iframe></div>');
    $("#new-enrollment-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
    $("#a-new-enrollment").live("click", function() {
      $("#new-enrollment-dialog").dialog('open');
    });
  } else {
      $("#enrollment-area").html('');
  }
}

function hideCurrentEnrollment(functocall) {
  if (current_enrollment_edit != 0) {
    $("#div_"+current_enrollment_edit).slideUp("fast", function() {
      $(".edit-enrollment").remove();
      $('#tr_enrollment_'+current_enrollment_edit).animate({ backgroundColor: "white" }, 1000, function() {
        $('#tr_enrollment_'+current_enrollment_edit).removeClass("selected");
        if (typeof functocall !== "undefined") {
          eval(functocall);
        }
      });
    });
  }

}

var current_enrollment_edit = 0;
$(".enrollment-item").live("click", function() {
  program_id = $('#program_id').val();
  term_id = $('#enrollment_term_id').val();
  var enrollment_id = $('#'+this.id).attr('enrollment_id');
  var tr_enrollment_id = this.id;
  if (current_enrollment_edit != enrollment_id) {
    if (current_enrollment_edit != 0) {
      current_enrollment_edit2 = current_enrollment_edit;
      $("#div_"+current_enrollment_edit).slideUp("fast", function() {
        $("#edit-course_"+current_enrollment_edit2).remove();
        $('#tr_enrollment_'+current_enrollment_edit2).animate({ backgroundColor: "white" }, 1000, function() {
          $('#tr_enrollment_'+current_enrollment_edit2).removeClass("selected");
        });
      });
    }

    url = location.pathname + '/' + program_id + '/periodo/' + term_id + '/inscripcion/' + enrollment_id;
    $("<tr class=\"edit-subitem edit-enrollment\" id=\"edit-course_" + enrollment_id + "\"><td colspan=\"6\"><div class=\"edit-course-div\" id=\"div_"+enrollment_id+"\"></div></td></tr>").insertAfter($('#'+this.id));
    $.get(url, {}, function(html) {
      $('#'+tr_enrollment_id).animate({ backgroundColor: "#dddddd" }, 1000);
      $("#div_"+enrollment_id).hide();
      $('<iframe />', {
        id: 'edit-student-iframe' + enrollment_id,
        src: url,
        scrolling: 'no',
        onload: "autoResizeIFRAME('edit-student-iframe" + enrollment_id + "')"
        //onload: "autoResizeIFRAME('edit-schedule-iframe" + enrollment_id + "')"
      }).appendTo("#div_"+enrollment_id);

      $("#div_"+enrollment_id).slideDown("fast", function() {
        $('#'+tr_enrollment_id).addClass("selected");
      });
    });
    current_enrollment_edit = enrollment_id;
  } else {
    $("#div_"+enrollment_id).slideUp("fast", function() {
      $(".edit-enrollment").remove();
      $('#'+tr_enrollment_id).animate({ backgroundColor: "white" }, 1000, function() {
        $('#'+tr_enrollment_id).removeClass("selected");
      });
    });
    current_enrollment_edit = 0;
  }
});

// Attendee
function loadAttendee(g) {
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();
  if (null === g) g = '';
  if ((term_id > 0) && (course_id > 0)) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/asistencia/" + g;
    $.get(url, {}, function(html) {
      $("#program-area").html(html);
    });
  } else {
      $("#program-area").html('');
  }
}

// Documentation

function loadDocumentation(g){
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();
  if (null === g) g = '';
  if ((term_id > 0) && (course_id > 0)) {
    url = location.pathname + "/" + program_id + "/periodo/" + term_id + "/curso/" + course_id + "/documentacion/" + g;
    $.get(url, {}, function(html) {
      $("#program-area").html(html);
    });
  } else {
      $("#program-area").html('');
  }
}

// Change group 
$('#tc_group').live("change", function() {
  if ($('#tc_group').val() == 0) {
    openNewGroupDialog();
  } else {
    if (current_option == 'students') {
      loadStudents($('#tc_group').val());
    } else if (current_option == 'schedule') {
      loadSchedule($('#tc_group').val());
    } else if (current_option == 'attendee') {
      loadAttendee($('#tc_group').val());
    } else if (current_option == 'documentation'){
      loadDocumentation($('#tc_group').val());
    }
  }
});

function openNewGroupDialog() {
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();

  $("#new-group-dialog").remove();
  url = '/programas/' + program_id + '/periodo/' + term_id + '/curso/' + course_id + '/nuevo_grupo';
  $('#content-panel').append('<div title="Nuevo grupo" id="new-group-dialog"><iframe width="550" height="140" src="' + url + '" scrolling="no"></iframe></div>');
  $("#new-group-dialog").dialog({ autoOpen: true, width: 590, height: 250, modal:true });
}

function loadGroupsDropdown(g) {
  program_id = $('#program_id').val();
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  url = '/programas/' + program_id + '/periodo/' + term_id + '/curso/' + course_id + '/groups_dropdown/' + g;
  $.get(url, {}, function(html) {
    $("#groups-dropdown").html(html);
  });
}

// Update staff to group
$("#update-staff-group").live("click", function() {
  openUpdateStaffGroupDialog();
});

function openUpdateStaffGroupDialog() {
  term_id = $('#tc_term_id').val();
  course_id = $('#tc_course_id').val();
  program_id = $('#program_id').val();
  g = $('#tc_group').val();

  $("#update-group-dialog").remove();
  url = '/programas/' + program_id + '/periodo/' + term_id + '/curso/' + course_id + '/grupo/' + g + '/cambiar_titular';
  $('#content-panel').append('<div title="Cambiar titular" id="update-group-dialog"><iframe width="550" height="140" src="' + url + '" scrolling="no"></iframe></div>');
  $("#update-group-dialog").dialog({ autoOpen: true, width: 590, height: 250, modal:true });
}

