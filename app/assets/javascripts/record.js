  var my_id;    
  function display_status(type,my_id){
    if(type=="ok"){
      $("#img_ok_"+my_id).css("display","block");
      $("#img_load_"+my_id).css("display","none");
      $("#img_fail_"+my_id).css("display","none");
    }
    else if(type=="load"){
      $("#img_ok_"+my_id).css("display","none");
      $("#img_load_"+my_id).css("display","block");
      $("#img_fail_"+my_id).css("display","none");
    }
    else if(type=="fail"){
      $("#img_ok_"+my_id).css("display","none");
      $("#img_load_"+my_id).css("display","none");
      $("#img_fail_"+my_id).css("display","block");
    }
  }

  $(document).ready(function() {
    $('.folder-record')
      .live('click',function(){
        var arr = $(this).attr("id").split("_");
        var id  = arr[1];
        if(isNaN(id)){
          $(".content-folder:hidden").show();
          $(".folder:visible").hide();
          $(".return:visible").hide();
          $(".return").first().show();
        }
        else{
          $(".content-folder:visible").hide();
          $(".folder:visible").hide();
          $(".return:hidden").show();
          cf = $("#cf-"+id)
          cf.show();
        }
      })
      .live('mouseover',function(){
        $(this).attr("height","60px");
      })
      .live('mouseout',function(){
        $(this).attr("height","50px");
      });

    $(".return")
      .live('click',function(){
        $(".content-folder:visible").hide();
        $(".folder:hidden").show();
      })
      .live('mouseover',function(){
        $(this).attr("height","45px");
      })
      .live('mouseout',function(){
        $(this).attr("height","40px");
      });
    
    $(".reqdoc_button_download").click(function(){
      my_id           = $(this).attr("my_id");
      var my_file_id  = $(this).attr("my_file_id");
      $("#files_iframe2").attr("src","/estudiantes/file/"+my_file_id);
    });

    $(".reqdoc_button_delete").click(function(){
      my_id           = $(this).attr("my_id");
      var my_file_id  = $(this).attr("my_file_id");
      display_status("load",my_id);
      $("#files_iframe2").attr("src","/estudiantes/destroy_file/"+my_file_id);
    });
    
    $(".reqdoc_button").click(function(){
      my_id   = $(this).attr("my_id");
      display_status("load",my_id);

      var form_id = "#reqdoc-form-"+my_id;
      $(form_id).submit();
    });  
    
    $("#files_iframe2").load(function(){
      var sts = $('#files_iframe2').contents().find("status").html();
      var ref = $('#files_iframe2').contents().find("reference").html();
      
      if(sts=="0")
      {
        errors  = $('#files_iframe2').contents().find("errors").html();
        alert(errors);

        if(ref=="upload"){
          display_status("fail",my_id);
        }
        else if(ref=='destroy')
        {
          display_status("ok",my_id);
        }
      }
      else if(sts=="1")
      {
        if(ref=="upload")
        {
          var new_id = $('#files_iframe2').contents().find("id").html();
          display_status("ok",my_id);
          $("#applicant_file_file_"+my_id).css("display","none");
          $("#reqdoc_button_"+my_id).css("display","none");
          $("#reqdoc_button_download_"+my_id).css("display","block");
          $("#reqdoc_button_delete_"+my_id).css("display","block");
          
          $("#reqdoc_button_"+my_id).attr("my_file_id",new_id);
          $("#reqdoc_button_download_"+my_id).attr("my_file_id",new_id);
          $("#reqdoc_button_delete_"+my_id).attr("my_file_id",new_id);
        }
        else if(ref=="destroy")
        {
          display_status("fail",my_id);
          $("#applicant_file_file_"+my_id).css("display","block");
          $("#reqdoc_button_"+my_id).css("display","block");
          $("#reqdoc_button_download_"+my_id).css("display","none");
          $("#reqdoc_button_delete_"+my_id).css("display","none");
        }
      }
    });//fin files_iframe

  });// fin document ready