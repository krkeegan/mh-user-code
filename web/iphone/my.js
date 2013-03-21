
function updateState (){
  var xmlhttp;
  if (window.XMLHttpRequest) { // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else { // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.onreadystatechange=function(){
    if (xmlhttp.readyState==4 && xmlhttp.status==200){
      //What to do when we get a response
      //document.getElementById("wa" + item).innerHTML=xmlhttp.responseText;
      var pairs=xmlhttp.responseText.split("|");
      var length = pairs.length;
      for (var i = 0; i < length; i++) {
        var item = pairs[i].split(",");
        // Dont change color of weather items
        if (item[0] !== "" && item[0].indexOf("w_") !== 0){
            document.getElementById(item[0] + "_state").innerHTML = item[1];
            if (item[1] == "on" || item[1] == "on_fast"){
                document.getElementById(item[0] + "_state").style.color="red";
            } else {
                document.getElementById(item[0] + "_state").style.color="black";
            }
        }
      }
      //Update time
      var d = new Date();
      var h = d.getHours();
      var m = d.getMinutes();
      $("#refresh_time .ui-btn-text").text(h + ':' + m);
      xmlhttp.close;
      setTimeout(function(){updateState()},1000);
    } else if (xmlhttp.readyState==4){
      xmlhttp.close;
    }
  };
  xmlhttp.open("GET","/iphone/update.pl",true);
  xmlhttp.send();
}

function setState (item, state){
  var xmlhttp2;
  if (window.XMLHttpRequest) { // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp2=new XMLHttpRequest();
  }
  else { // code for IE6, IE5
    xmlhttp2=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp2.onreadystatechange=function(){
    if (xmlhttp2.readyState==4 && xmlhttp2.status==200){
      xmlhttp2.close;
      setTimeout(function(){updateState()},1000);
    }
  };
  xmlhttp2.open("GET","../SET;OK?$" + item + "=" + state,true);
  xmlhttp2.send();
}

$(document).ready(function(){
    $.mobile.transitionFallbacks.slide = "none";
});