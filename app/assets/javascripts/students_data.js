$(document).ready(function() {
  option = "highest"
  order(option);

  $("button.first").css("background-color","#f7f7e7");

  $("#div.order").click(function(){
    if(option=="highest"){
      option="lowest"
      order(option);
    }else if(option=="lowest"){
      option="highest"
      order(option);
    }
  });

  $("button").click(function(){
    filter = $(this).html();
    $("button").css("background-color","#e7e7e7")
    $(this).css("background-color","#f7f7e7")
   
    switch(filter){
      case "todo":
        $("#div.body #div.row").show();
        break;
      default:
        $("#div.body #div.row").hide();
        $("#div.body #div."+filter).show();
        break;
    }
  });

  function order(option){
    $("#div.body #div.row").sort(function(a,b){
      if(option=="highest"){
        return new Date($(a).find(".fecha").html()) > new Date($(b).find(".fecha").html());
      }else if(option=="lowest"){
        return new Date($(a).find(".fecha").html()) < new Date($(b).find(".fecha").html());
      }
    }).each(function(){
      $("div.body").prepend(this);
    });
  }
});

