var model_name = 'applicant';
var doctorate = ["2","4","10"];

$(document).ready(function() {
  $(".first-page").live("change",function(){
    var program_id = $("#applicant_program_id").val();
    var campus_id  = $("#applicant_campus_id").val();
    var place_id   = $("#applicant_place_id").val();
    /* Si no es doctorado tienen que estar llenos todos */
    if(doctorate.indexOf(program_id)!=-1){
      if(program_id && campus_id) {
        $("#ok_button").show();
      }
    }else{
      if(program_id&&campus_id&&place_id) {
        $("#ok_button").show();
      }
    }
  });

  $("#applicant_program_id").live("change", function(){
    program_id  = $(this).val();
    if(!program_id)
    {
      return false;
    }

    $("#img_load_campus").show();
    $(this).prop("disabled","disabled");
    $(".aux_field_campus").hide();
    uri = '/aspirantes/registro/obtener/campus/'+program_id;
    data = ""
    $.ajax({
      type:  'POST',
      url:   uri,
      data:  data,
      beforeSend: function( xhr ) {
      },
      success:  function(data){
        set_campus(data.campus)
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
        $("#img_load_campus").hide();
        $("#applicant_program_id").removeAttr("disabled");
        $(".aux_field_campus").show();
        /* si es doctorado no pedimos sede */
        if(doctorate.indexOf(program_id)!=-1){
          $(".aux_field_place").hide();
        }else{
          $(".aux_field_place").show();
        }
      },
    });
  });
 
  $("#ok_button").live("click", function(){
    var program_id = $("#applicant_program_id").val();
    var campus_id  = $("#applicant_campus_id").val();
    var place_id   = $("#applicant_place_id").val()
    if(program_id && campus_id && place_id) {
      var program = $("#applicant_program_id option:selected").text();
      var campus  = $("#applicant_campus_id option:selected").text();
      var place   = $("#applicant_place_id option:selected").text();
      /*$("#applicant_program_id").prop("disabled","disabled");
      $("#applicant_campus_id").prop("disabled","disabled");
      $("#applicant_place_id").prop("disabled","disabled");
      /*$(this).prop("disabled","disabled");*/
      $("#info").html("<h4><b>Programa:</b> "+program+"<br><b>Campus: </b>"+campus+"<br><b>Sede: </b>"+place+"</h4>");
      $("#img_load").show();
      $("#first_screen").hide();
      get_form(program_id);
    }
    else if(program_id && campus_id ) {
      var program = $("#applicant_program_id option:selected").text();
      var campus  = $("#applicant_campus_id option:selected").text();
      $("#info").html("<h4><b>Programa:</b> "+program+"<br><b>Campus: </b>"+campus+"<br></h4>");
      $("#img_load").show();
      $("#first_screen").hide();
      get_form(program_id);
    }
    else
    {
      alert("Ha dejado campos vacios");
    }
  });
  
  $('#item-new-form')
    .live('ajax:success', function(evt, data, status, xhr) {
      var res = $.parseJSON(xhr.responseText);
      /*alert(res['flash']['notice']);*/
      if(res['uniq']){
        window.location="/aspirantes/"+res['uniq']+"/archivos/registro";
      }else{
        alert("Error: no se ha recibido id de aspirante");
      }
    })// live sucess

    .live("ajax:error", function(evt, xhr, status, error) {
      try {
        res = $.parseJSON(xhr.responseText);
        //alert(res['errors_full'])*/
        res = $.parseJSON(xhr.responseText);
        $.each(res['errors_full'],function(key,value){
          if(value.match("0x0")){
            alert("Ya existe un registro con ese nombre");
          }
        })

      } catch(err) {
        alert("Error general");
      }
    })//live error

});//document.ready

/********************* FUNCIONS ****************************/
function set_campus(campus){
  $("#ok_button").hide();
  var api =   $("#applicant_campus_id");
  api.find('option').remove().end();
  var option1 = document.createElement("option");
  $(option1).val("");
  $(option1).append("Elige el campus");
  api.append(option1);
  $(campus).each(function(index,c){
    var option = document.createElement("option");
    $(option).val(c.id);
    $(option).append(c.name);
    api.append(option);
  });
}

function get_form(program_id){
 
 if(doctorate.indexOf(program_id)!=-1){
   $("#field_applicant_staff_id").show();
 }
 
 $("")
 $("#my_fields").show();
 $("#img_load").hide();
}
