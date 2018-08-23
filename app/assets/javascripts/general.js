var studies_plans_flag = 0;
var item_edit_form_func = 0;
var objects;
var items = [];
var items_found = [];

var please = "<center><br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<h2>Presionar Enter para seleccionar el primer resultado o seleccionar con el Mouse</h2></center>";

delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();

function calcFrameHeight(id) {
  iframe = document.getElementById(id);
  try
  {
    var innerDoc = (iframe.contentDocument) ? iframe.contentDocument : iframe.contentWindow.document;
    if (innerDoc.body.offsetHeight) { //ns6 syntax
      iframe.height = innerDoc.body.offsetHeight + 32; //Extra height FireFox
    } else if (iframe.Document && iframe.Document.body.scrollHeight) { //ie5+ syntax
      iframe.height = iframe.Document.body.scrollHeight;
    }
  } catch(err) {
    alert(err.message);
  }
}

function changeResourceImage(id, small, medium) {
  if (small != $('#img-small-' + id).attr('src')) {
    $('#img-small-' + id).attr('src', small);
    $('#img-medium-' + id).attr('src', medium);
  }
}

function liveSearch(options) {
    options = (typeof options === 'undefined') ? 'default' : options;

    $("#search-box").addClass("loading");

    $("#content-panel").html("<img src=\"\/images\/ajax-load2.gif\">");
    
    if(options.json){
      $("#searchy").val("");
      $("#searchy").attr("disabled","disabled");
      $("#items-list").html("<img src=\"\/images\/ajax-load2.gif\">");
    }

    var form = $("#live-search");
    var url = location.pathname + "/busqueda";
    var formData = form.serialize();
    $.get(url, formData, function(html) {
        if(options.json){
            objects = jQuery.parseJSON(html);
            items       = [];
            items_found = [];
            $.each(objects, function(key,val){
              items.push(getLi(val));
              items_found.push(val.id);
            });

            setItems(items);           
            $("#searchy").removeAttr("disabled");
            $("#content-panel").html("<img src=\"\/images\/ajax-load2.gif\">");
        }else{
          $("#search-box").removeClass("loading");
          $("#items-list").html(html);
        }

        $("#items-list li:first a").click();
        /*$("#searchy").focus();
        $("#content-panel").html(please);*/
    });
}

$("#searchy").live("keyup", function(e){
  search(e);
});

function search(e){
  var searchField = $('#searchy').val();
  
  var command = "";
  command = searchCommand(searchField);

  if(!command){
    if(searchField.length==1){
      return false;
    }
  }

  var keys = [9,16,17,18,19,20,27,33,34,35,36,37,38,39,40,41,42,43,44,45,91,92,93,112,113,114,115,116,117,118,119,120,121,122,123,144,145,192];
  if(keys.indexOf(e.which)!=-1){return false;}


  if(!$("#first_check").prop("checked")){
    $("#content-panel").html(please);

    if(e.which==13){ // ENTER press
      if(items.length==0)
      {
        $("#content-panel").html("<p>&nbsp;<p>&nbsp;<p>&nbsp;<center><h2>Sin resultados</h2></center>");
        return;
      }
      else{

        $("#content-panel").html("<img src=\"\/images\/ajax-load2.gif\">");
        $("#items-list li:first").addClass("selected");
        $("#items-list li:first a").click();
        return;
      }
    }
  }

  if(!$("#accent_check").prop("checked")){
    searchField = accent_finder(searchField);
  }
  searchByCommand(command,searchField);
  setItems(items);

  if($("#first_check").prop("checked")){
    $("#content-panel").html("<img src=\"\/images\/ajax-load2.gif\">");
    $("#items-list li:first").addClass("selected");
    $("#items-list li:first a").click();
  }
}

function searchCommand(searchField){
  var command = {"command": null, "data": null};

  var regex   = new RegExp("^\\d+$");
  if(searchField.search(regex) != -1){
    command.command = "id";
    command.data = searchField
    return command;
  }

  var regex   = new RegExp("^[A-Z][A-Z]+\\d*$");
  if(searchField.search(regex) != -1){
    command.command = "card";
    command.data = searchField
    return command;
  }

  return false;
}

function searchByCommand(command,searchField){
  var regex   = new RegExp(searchField, "i");
  var counter = 0;
  items       = [];
  items_found = [];

  switch(command.command){
    case "id":
      $.each(objects,function(key,val){
        if(val.id==command.data){
          items.push(getLi(val));
          items_found.push(val.id);
        }
      });
      break;
    case "card":
      $.each(objects,function(key,val){
        var regex = new RegExp(command.data,"i")
        if(val.card.search(regex) != -1){
          items.push(getLi(val));
          items_found.push(val.id);
        }
      });
      break;
    case "gender":
      $.each(objects,function(key,val){
        //var regex = new RegExp(command.data,"i")
        if(val.gender==command.data){
          items.push(getLi(val));
          items_found.push(val.id);
        }
      });
      break;
    default:
      $.each(objects,function(key,val){
        var my_search_text = ""
        if($("#accent_check").prop("checked")){
          my_search_text = val.first_name+" "+val.last_name
        }else{
          my_search_text = accent_finder(val.first_name+" "+val.last_name);
        }

        if(my_search_text.search(regex) != -1){
          items.push(getLi(val));
          items_found.push(val.id);
        }
      });
  }
}

function accent_finder(s)
{
  var accentMap = {
    'á':'a','é':'e','í':'i','ó':'o','ú':'u', 'à':'a','è':'e','ì':'i','ò':'o','ù':'u','ä':'a','ë':'e','ï':'i','ö':'o','ü':'u'
  };

  for (var i=0;i<s.length;i++)
  {
    var c = accentMap[s.charAt(i)];
    if(c){ 
      s = s.replace(s[i],c);
    }
  }

  return s;
}

function getLi(val){
  var full_name = val.first_name+" "+val.last_name;
  var program   = "N.D";

  $.each(programs, function(k, v) {
    if(v.id==val.program_id){
      program = v.name;
      return;
    }
  });
  
  var img  = "<img id=\"img-small-"+val.id+"\" src=\""+val.image.small.url+"\" alt=\"Small_Default\">"
  var divs = "<div class=\"title\">"+full_name+"<\/div><div class=\"comment\">"+program+"<\/div>"
  var li  = "<li><a id=\"student_link_"+val.id+"\" class=\"get-item\" href=\"\/estudiantes\/"+val.id+"\" data-type=\"html\" data-remote=\"true\" data-method=\"get\">"+img+divs+"<\/a></li>"
  return li;
}

function setItems(items){
  var ul = $("<ul class=\"panel-list\"></ul>").html(items.join("")); 
  $("#items-list").html(ul); 
  var counter = "<div id=\"counter\"><div class=\"inner\">"+items.length+"<\/div><\/div>"
  $("#items-list").append(counter); 
}


function showFormErrors(xhr, status, error) {
    var res,
        errorText,
        errorMs,
        errorMesg;
    try {
        res = $.parseJSON(xhr.responseText);
    } catch(err) {
        res['errors'] = { generic_error: "Error:" + err.description };
    }

    errorMesg="";
    try{
      $.each(res['errors_full'],function(key,value){
        numlist = key + 1
        errorMesg+=" "+numlist+": "+value+"<br>";
      });
    }catch(err){
      $.each(res['errors'],function(key,value){
        numlist = key + 1
        errorMesg+=" "+numlist+": "+value+"<br>";
      });
    }

    for ( e in res['errors'] ) {
        errorMsg = $('<div>' + res['errors'][e] + '</div>').addClass('error-message');
        $('#field_' + model_name + '_' + e.replace('.', '_')).addClass('with-errors').append(errorMsg);
    }

    showFlash(res['flash']['error'], 'error', errorMesg);
}

function showFlash(msg,type,errors) {
    try{
      fn = $("#flash-notice",window.parent.document);
      if (!errors){errors="";}
      $(fn).removeClass('success').removeClass('notice').removeClass('info');
      $(fn).addClass(type).html(msg +"<p>"+ errors);
      $(fn).slideDown();
      if (type != 'error') {
        $(fn).delay(1500).slideUp();
      }
    }catch(e){
      if (!errors){errors="";}
      $("#flash-notice").removeClass('success').removeClass('notice').removeClass('info');
      $("#flash-notice").addClass(type).html(msg +"<p>"+ errors);
      $("#flash-notice").slideDown();
      if (type != 'error') {
        $("#flash-notice").delay(1500).slideUp();
      }
    }
}

/************* READY! **************************/
$(document).ready(function() {

$("#flash-notice").live('click', function() {
    $(this).slideUp();
    $(this).removeClass('error').removeClass('success').removeClass('notice').removeClass('info');
});

$("#search-box").live("keyup", function(e) {
   if(e.which==13){
    liveSearch();
   }
  });

// ** Get Item **
$('.get-item')
  .live('ajax:success', function(data, status, xhr) {
    page = 1
    $('.panel-list li').removeClass("selected");
    $('.panel-add').removeClass("selected");
    $(this).closest('li').addClass("selected");
    $('#content-panel').html(status);
    $(function() {  $('#resource-tabs').tabs(); });

    /** Disable/enable submit button **/
    //$('#content-panel form').find (':submit').attr('disabled', 'disabled').addClass('disabled');
    $('#content-panel form').find('input[type="submit"]').attr('disabled', 'disabled').addClass('disabled');

    var form = $('#content-panel form');
    $(':input', form.get(0)).live ('change', function (e) {
       form.find (':submit').removeAttr('disabled').removeClass('disabled');
    })
  })

  .live('ajax:beforeSend', function(ev, xhr, settings) {
     $(this).closest('li').addClass("loading");
  })

  .live("ajax:error", function(data, status) {
    console.log(data);
    console.log(status);
   })

  .live('ajax:complete', function(evt, xhr, status) {
     $(this).closest('li').removeClass("loading");
  });

$('#add-new-item')
  .live('ajax:beforeSend', function(ev, xhr, settings) {
     $('.panel-add').addClass("selected");
     $('.panel-list li').removeClass("selected");
   })

  .live("ajax:error", function(data, status) {
    console.log(data);
    console.log(status);
   })

  .live('ajax:success', function(data, status, xhr) {
    $('#content-panel').html(status);
    $(function() {  $('#resource-tabs').tabs(); });

    /** Disable/enable submit button **/
    $('#content-panel form').find (':submit').attr('disabled', 'disabled').addClass('disabled');

    var form = $('#content-panel form');
    $(':input', form.get(0)).live ('change', function (e) {
        form.find (':submit').removeAttr('disabled').removeClass('disabled');
    })
  }
)

$('#item-new-form')
    .live("ajax:beforeSend", function(evt, xhr, settings) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.data( 'origText', $(this).text() );
        $submitButton.text( "Creando..." );
        $('.error-message').remove();
        $('.with-errors').removeClass('with-errors');
    })

    .live("ajax:success", function(evt, data, status, xhr) {
        // Load new
        var $form = $(this);
        var res = $.parseJSON(xhr.responseText);
        showFlash(res['flash']['notice'], 'success');

        if(res['version']==1){
          liveSearch({json: true});
          $("#searchy").val(res['uniq']);
          setTimeout(function(){
            var e = jQuery.Event("keyup");
            search(e);
            $("#items-list li:first").addClass("selected");
            $("#items-list li:first a").click();
          }, 1000);
        } 
        else{
          $("#search-box").val(res['uniq']);
          try{
            initializeSearchForm();
            liveSearch();
          }
          catch(e)
          {
           // let it pass
          }
        }
    })

    .live('ajax:complete', function(evt, xhr, status) {
        var $submitButton = $(this).find('input[type="submit"]');
        if(status=="error")
        {
          $submitButton.removeClass('disabled');
          $submitButton.attr('disabled',false);
        }
        else{
          $submitButton.text( $(this).data('origText') );
          $submitButton.attr('disabled', 'disabled').addClass('disabled');
        }
    })

    .live("ajax:error", function(evt, xhr, status, error) {
        showFormErrors(xhr, status, error);
    }
);

$('#item-new-internship-applicant-form')
    .live("ajax:beforeSend", function(evt, xhr, settings) {
      var submitButton = $(this).find('input[type="submit"]');
      submitButton.attr('disabled','disabled');
      var text = $("#internship_email").val();
      if(text==""){
        alert("El email es obligatorio");
        submitButton.attr('disabled',false);
         $("#internship_email").focus();
        return false;
      }
      $('.error-message').remove();
      $('.with-errors').removeClass('with-errors');
      $('#img_load').show();
    })
    .live("ajax:success", function(evt, data, status, xhr) {
        // Load new
        var res    = $.parseJSON(xhr.responseText);
        var html   = ''
        if(res['uniq']!=0){
          if(res['internship_type_id']==8)
          {
            html = "<h3>Se ha dado de alta su solicitud y se ha enviado un mensaje con instrucciones al correo que ha registrado.</h3>"
          }
          else
          {
            var uri = res['uri']
            html = "<h3>Se ha dado de alta su solicitud y se ha enviado un mensaje con instrucciones a su correo, puede descargar e imprimir su formato de registro: <a href="+uri+">Descargar</a></h3>"
          }
          $('#applicantFormContent').html(html);
        }
    })
    .live("ajax:error", function(evt, xhr, status, error) {
        var res = $.parseJSON(xhr.responseText);
        var submitButton = $(this).find('input[type="submit"]');
        submitButton.attr('disabled',false);
        showFormErrors(xhr, status, error);

    })
    .live('ajax:complete', function(evt, xhr, status) {
        var submitButton = $(this).find('input[type="submit"]');
        submitButton.attr('disabled',false);
        $('#img_load').hide();
    })


$('#item-edit-form')
    .live("ajax:beforeSend", function(evt, xhr, settings) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.data( 'origText', $(this).text() );
        $submitButton.text( "Actualizando..." );
        $('.error-message').remove();
        $('.with-errors').removeClass('with-errors');
    })

    .live("ajax:success", function(evt, data, status, xhr) {
        var $form = $(this);
        var res = $.parseJSON(xhr.responseText);
        if(res['graduated']==1){$("#graduate-dialog").dialog('open');}
        showFlash(res['flash']['notice'],'success');
    })

    .live('ajax:complete', function(evt, xhr, status) {
        var $submitButton = $(this).find('input[type="submit"]');
        $submitButton.text( $(this).data('origText') );
        $submitButton.attr('disabled', 'disabled').addClass('disabled');
        if(item_edit_form_func==1){
          itemEditFormFunc();
        }
    })

    .live("ajax:error", function(evt, xhr, status, error) {
        showFormErrors(xhr, status, error);
    }
);
  
  /*****************  MENU SYSTEM EVENTS ****************/
  
  /** cuando damos click en cualquier parte excepto el menú, reseteamos el menú **/
  $("html:not(#nav-system-menu ul.main-nav)").click(function(){
    $("#nav-system-menu ul.body-nav").css("display","none");
    $("#nav-system-menu ul.body-nav").css("position","");
    $("#nav-system-menu li").css("float","");

    $("#nav-system-menu ul li ul").css("display","none");
    $("#nav-system-menu ul li ul").css("position","");
  });

  /** Cuando damos click en la cabecera del menú **/
  $("#nav-system-menu ul.main-nav").click(function(e){
    if (!e) var e = window.event;
    // ie
    e.cancelBubble = true;
    e.returnValue = false;
    // ff / webkit
    if (e.stopPropagation) {
      e.stopPropagation();
      //e.preventDefault();
      e.defaultPrevented;
    }

    $("#nav-system-menu a.tree-nav").each(function(){
      $(this).removeClass("colored");
    });

    if($("#nav-system-menu ul.body-nav").css("display")=="none")
    {
      $("#nav-system-menu ul.body-nav").css("display","block");
      $("#nav-system-menu ul.body-nav").css("position","absolute");
      $("#nav-system-menu li").css("float","none");
    }
    else{
      $("#nav-system-menu ul.body-nav").css("display","none");
      $("#nav-system-menu ul.body-nav").css("position","");
      $("#nav-system-menu li").css("float","");
    }



    e.stopPropagation();
    e.preventDefault();
  });
  
  // si el link es tree mostramos los hijos (que en realidad son hermanos)
  $("#nav-system-menu a.tree-nav").click(function(e){
    // identificamos el padre
    var li = $(this).parent();
    var tree_nav = $(this);
    if($(this).attr("menu_counter")==1){
        $(this).removeClass("colored")
        $(this).parent().find("ul").css("display","none");
        $(this).parent().find("ul").css("position","");
        tree_nav.attr("menu_counter",0);
    }//if
    else{
      $("#nav-system-menu a.tree-nav").each(function(){
          $(this).removeClass("colored")
          $(this).parent().find("ul").css("display","none");
          $(this).parent().find("ul").css("position","");
          $(this).attr("menu_counter",0);
      });//nav-system-menu a.tree-nav

        $(li).find("ul").each(function(){
          $(this).css("display","block");
          $(this).css("position","absolute");
          $("#nav-system-menu li").css("float","none");
          tree_nav.attr("menu_counter",1);
          tree_nav.addClass("colored");
        });
    }//else


    e.stopPropagation();
    e.preventDefault();
  });

  // para direccionar los links que no son tree
  $("#nav-system-menu ul li a").click(function(e){
    var href = $(this).attr("href");
    if(!(href==undefined)){
      window.location.href = href;
    }    
  });


});  // READY


function autoResizeIFRAME(id){
  var newheight;
  var newwidth;
  if(document.getElementById){
    newheight=document.getElementById(id).contentWindow.document.body.scrollHeight;
    newwidth=document.getElementById(id).contentWindow.document.body.scrollWidth;
  }
  document.getElementById(id).height = (newheight) + "px";
  document.getElementById(id).width = (newwidth) + "px";
}

function getCookie(cookie){
  var cookies = document.cookie;
  var cookies_s = cookies.split(";");
  var to_return = false
  $.each(cookies_s,function(i,v){
     var regex   = new RegExp(cookie);
     if(v.search(regex) != -1){
       var result = v.split("=");
       to_return = result[1];
       return false
     }
  });

  return to_return;
}
