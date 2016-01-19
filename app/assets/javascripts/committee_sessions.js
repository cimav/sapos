var model_name = 'committee_session'
var counter    = 1 

$(document).ready(function() {
  liveSearch();
  $("#new-term-dialog").dialog({ autoOpen: false, width: 640, height: 450, modal:true });
});

function initializeSearchForm() {
  var a = 1;
}

$('#item-edit-form')
  .live('ajax:success', function(evt, data, status, xhr) {
    $(".delete-agreement").hide();
    $(".save-text-agreement").hide();
    $(".agreement-group").hide();
    $(".delete-agreement-staff").hide();
    $(".delete-attendee-span").hide();

    $(".response-agreement").show();
    $("#memorandum_button").show();

    $(".save-date-agreement").prop("disabled","disabled");
    $(".save-note-agreement").prop("disabled","disabled");
    $(".agreement_auth").prop("disabled","disabled");
    $(".roll-checkbox").prop("disabled","disabled")
    $("#committee_session_date").prop("disabled","disabled");

    $("#div_agreements").find("div[class*='select2-container']").each(function(){
      $(this).select2("disable");
    });

    $("#session_hour").select2("disable");
    $("#session_minutes").select2("disable");
    $("#staff_combo").select2("disable");

    $("#comment_session_"+$("#c_session_id").val()).html("Finalizada")
  });

$("#staff_combo").live("change",function(e){
  if(e.val!=""){
    var session_id = $("#c_session_id").val();
    var len= $(".staff_hidden[value="+e.val+"]").size();
 
    if(len==0){
      text = $("#staff_combo option[value='"+e.val+"']").text();
      if(!isNaN(session_id)){
        set_staff(session_id,e.val,text);
      }
      else{
        html = "<span id='staff_span_"+counter+"' class='staff-span'><input type='hidden' class='staff_hidden' id='staff_"+counter+"' value="+e.val+">"+text+" <span class='delete-attendee-span'>[<u class='delete-attendee' id='delete_attendee_"+counter+"' my_id="+counter+" style=\"cursor: pointer\">eliminar</u>]</span><br></span>";
        $("#div_attendees").append(html);
      }
      counter = counter + 1
      reset_total();
    }
  }
});

function set_staff(session_id,staff_id,text){
  $("#img_load_sesion").show();
  var data =  "";
  uri = 'comite/sesion/asistencia/agregar/'+session_id+'/'+staff_id;
  $.ajax({
    type:  'POST',
    url:   uri,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      data = data.slice(0,-1);
      html = "<span id='staff_span_"+data+"' class='staff-span'><input type='hidden' class='staff_hidden' id='staff_"+data+"' value="+staff_id+">"+text+"<input class='roll-checkbox' id='chbx_"+data+"' name='chbx_"+data+"' value='"+data+"' type='checkbox'> <span class='delete-attendee-span'>[<u class='delete-attendee' id='delete_attendee_"+data+"' my_id="+data+" style=\"cursor: pointer\">eliminar</u>]</span><br></span>";
      $("#div_attendees").append(html);
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load_sesion").hide();
    },
  });
}

$('#item-new-form').live("ajax:before", function(ev,xhr,settings) {
  $(".staff_hidden").each(function(i){
    attes = $("#hidden_attendees").val();
    id = $(this).val();
    $("#hidden_attendees").val(id+","+attes);
  });
});

function reset_total(){
  $("#staff_span_total").html($(".staff-span").length)
}

$(".roll-checkbox").live("click",function(){
   $("#img_load_sesion").show();
   var valor = $(this).val(); 
   var url   = "/comite/sesion/asistencia/"+valor+"/"+$(this).prop("checked");
  var data =  "";
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      //$("#div_agreements").append(data);
      //p.remove();
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load_sesion").hide();
    },
  });
});

$(".delete-attendee").live("click",function(){
  var del_id = $(this).attr("my_id");
  var session_id = $("#c_session_id").val();
  if(!isNaN(session_id)){
    delete_attendee(del_id);
  }
  $("#staff_span_"+del_id).remove();
  reset_total();
});

function delete_attendee(csa_id)
{
  $("#img_load_sesion").show();
  var url   = "/comite/sesion/asistencia/borrar/"+csa_id;
  var data  =  ""
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
       //alert(data);
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load_sesion").hide();
    },
  });
}

$(".save-text-agreement").live("click",function(){
  var p     = $(this).parent();
  var my_id = p.find("#my_id").val();
  var texto = $("#my_notes_"+my_id).val();
  $("#commitee_agreement_notes").val(texto);
  $("#notes-agreement").attr("my_id",my_id);
  $("#new-term-dialog").dialog('open');
});

$(".notes-agreement").live("click",function(){
  var my_id = $(this).attr("my_id");
  var texto = $("#commitee_agreement_notes").val();
  $("#img_load").show();
  var url  = "/comite/acuerdos/texto/"+my_id;
  var data = "text="+texto;
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
       //alert(data);
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#my_notes_"+my_id).val(texto);
      $("#new-term-dialog").dialog('close');
      $("#img_load").hide();
    },
  });
});

$(".delete-agreement").live("click",function(){
  var p     = $(this).parent();
  var my_id = p.find("#my_id").val();
  if(!confirm("Eliminar acuerdo "+my_id+"?")){return false;}
  $("#img_load").show();
  var url  =  "/comite/acuerdos/borrar/"+my_id;
  var data =  "";
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      //$("#div_agreements").append(data);
      p.remove();
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load").hide();
    },
  });
});

function get_committee_agreements()
{
  var sesion_id = $("#c_session_id").val();
  var url  =  "/comite/acuerdos/"+sesion_id+"/todos";
  var data =  "";
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      $("#div_agreements").append(data);
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("select.save-note-agreement").select2();
      $("select.agreement_auth").select2();
      $("select.agreement_people").select2();
      $("#img_load").hide();
    },
  });


}

$("#agreement_button").live("click",function(e){
  /*var p       = $(this).parent();
  var my_id   = p.find("#my_id").val();*/
  var my_id   = 120
  var valor     = $("#agreement_combo").val();
  var sesion_id = $("#c_session_id").val();
  if(valor=="")
  {
    alert("Por favor seleccione un tipo de acuerdo");
    return false;
  }
  //var valor = $(this).val();
  $("#img_load").show();
  var url  =  "/comite/acuerdos/"+sesion_id+"/"+valor;
  var data =  "";
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      $("#div_agreements").append(data);
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      var arr = new Array();
      $("#div_agreements").find("input:hidden[name='my_id']").each(function(){
         arr.push($(this).val());
      });
      var max  = Math.max.apply(Math,arr);
      //alert(arr);
      $("select#save_note_agreement_"+max).select2();
      $("select#agreement_auth_"+max).select2();
      $("select#agreement_staffs_"+max).select2();
      $("select#agreement_applicants_"+max).select2();
      $("select#agreement_permanence_"+max).select2();
      $("select#agreement_cambio_prog_"+max).select2();
      $("select#agreement_cambio_prog_prog_"+max).select2();
      $("select#agreement_student_dir_tesis_"+max).select2();
      $("select#agreement_dir_tesis_dir_tesis_"+max).select2();
      $("#img_load").hide();
    },
  });
});

$(".response-agreement").live("click",function(e){
  //var sesion_id = $("#c_session_id").val();
  var p       = $(this).parent();
  var my_id   = p.find("#my_id").val();
  var sign_id = $("input[name='signer']:checked").val();
  var type  = $(this).attr("response_type");
  var url   =  "/comite/acuerdos/imprimir/"+my_id+"/"+sign_id;
  window.open(url, '_blank');
});

$("#memorandum_button").live("click",function(e){
  var my_id = $("#c_session_id").val();
  var url   =  "/comite/sesion/minuta/"+my_id;
  window.open(url, '_blank');
});

$(".agreement_people").live("change",function(e){
  $("#img_load").show();
  var sesion_id = $("#c_session_id").val();
  var p      = $(this).parent();
  var people = $(this).attr("autt");
  var a_id   = p.find("#my_id").val();
  var valor  = $(this).val();
  var nombre = $(this).find('option:selected').text();
  var url    =  "/comite/acuerdos/"+a_id+"/agregar/"+people+"/"+valor;
  var data= ""
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      if(data.estatus==4){
        alert("Solo pueden ser 5 sinodales");
      }
      else if(data.estatus==2){
        alert("El docente ya existe");
      }
      else{
        if(people=="sinodales"){
          html = "<div class='agreement-staff'><input id='my_sinodal_id' name='my_sinodal_id' value='"+data.person_id+"' type='hidden'>"+nombre+"<img alt='Grey_action_delete' class='delete-agreement-staff' src='/images/grey_action_delete.png' style='cursor: pointer; opacity: 0.3;' valign='center'></div>";
          $("#agreement-staffs_"+a_id).append(html);
        }
      }
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load").hide();
    },
  });
});

$(".delete-agreement-staff").live({
  mouseover: function(){
    $(this).css({ opacity: 1.0 })
  },
  mouseout: function(){
    $(this).css({ opacity: 0.3 });
  },
  click: function(){
    $("#img_load").show();
    var p     = $(this).parent();
    var valor = p.find("#my_sinodal_id").val();
    var url   = "/comite/acuerdos/persona/borrar/"+valor;
    var data= ""
    $.ajax({
      type:  'POST',
      url:   url,
      data:  data,
      beforeSend: function( xhr ) {
      },
      success:  function(data){
        p.remove();
      },
      error: function(xhr, textStatus, error){
         var text = xhr.responseText;
         try{
           var jq   = jQuery.parseJSON(xhr.responseText);
         }
         catch(e){
           alert("Error desconocido: "+e.message)
         }
      },
      complete: function(){
        $("#img_load").hide();
      },
    });
  }
});


$(".agreement_auth").live("change",function(e){
  $("#img_load").show();
  var sesion_id = $("#c_session_id").val();
  var p    = $(this).parent();
  var a_id = p.find("#my_id").val();
  var mtype = p.find("#my_type").val();
  var thisval = $(this).val(); 
  var url  =  "/comite/acuerdos/"+a_id+"/agregar/auth/"+thisval
  var data= ""
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      if(mtype==8)//Designacion de docentes para cursos
      {
         get_courses(thisval,a_id);
      }
      else if(mtype==9)//Autorizacion de materias nuevas
      {
         get_courses(thisval,a_id);
      }
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load").hide();
    },
  });
});

$(".save-date-agreement").live("change",function(e){
   agreement_note(this);
});

$(".save-note-agreement").live("change",function(e){
   agreement_note(this);
});

function agreement_note(t){
  $("#img_load").show();
  var sesion_id = $("#c_session_id").val();
  var p     = $(t).parent();
  var a_id = p.find("#my_id").val();
  var url  =  "/comite/acuerdos/"+a_id+"/agregar/note/"+$(t).val();
  var data= ""
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(data){
      //
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      $("#img_load").hide();
    },
  });
}

function get_courses(t,a_id)
{
  var url  = "/comite/traer/cursos/"+t;
  var data = ""
  $.ajax({
    type:  'POST',
    url:   url,
    data:  data,
    beforeSend: function( xhr ) {
    },
    success:  function(d){
      var option;
      $("#save_note_agreement_"+a_id+" option:gt(0)").remove();
      $.each(d.courses, function(value,key){
        name = key.name+" ("+key.prefix+")"
        option = new Option(name,key.id);
        $("#save_note_agreement_"+a_id).append(option);
      });
    },
    error: function(xhr, textStatus, error){
       var text = xhr.responseText;
       try{
         var jq   = jQuery.parseJSON(xhr.responseText);
       }
       catch(e){
         alert("Error desconocido: "+e.message)
       }
    },
    complete: function(){
      //
    },
  });
}


function start_datepicker()
{
  $.datepicker.setDefaults($.datepicker.regional["es"]);
  var config = {
    changeMonth: true,
    changeYear: true,
    dateFormat: 'yy-mm-dd',
    showButtonPanel: true,
    minDate: '-80Y',
    maxDate: '+2Y',
  };

  $( "#committee_session_date" ).datepicker(config);
  $( ".save-date-agreement" ).datepicker(config);
}
