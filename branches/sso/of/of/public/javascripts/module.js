var module = function(){};
module.js_path = "http://of.openfoundry.org/of/javascripts/";
module.logo_path = "http://www.openfoundry.org/Powered-by-OSSF-180x50";
module.site_path = "http://www.openfoundry.org/";

importJS(module.js_path+"jquery.js", "jQuery", function(){
  var pathname = location.pathname;
  _OF(jQuery);
  if(pathname.match(/^\/rt\/ticket\/create.html/i) || pathname.match(/^\/c/i)) {
    importJS(module.js_path+"jquery.validate.js", "jQuery.validator", function(){
      jQuery(document).ready(function(){OF.onload();});
    });
  }
  else {
    jQuery(document).ready(function(){OF.onload();});
  }
});

function importJS(src, look_for, onload) {
  var s = document.createElement('script');
  s.setAttribute('type', 'text/javascript');
  s.setAttribute('src', src);
  if (onload) wait_for_script_load(look_for, onload);
  if (eval("typeof " + look_for) == 'undefined') {
    var head = document.getElementsByTagName('head')[0];
    if (head) head.appendChild(s);
    else document.body.appendChild(s);
  }
}

function wait_for_script_load(look_for, callback) {
  var interval = setInterval(function() {
    if (eval("typeof " + look_for) != 'undefined') {
      clearInterval(interval);
      callback();
    }
  }, 50);
}

function _OF($){
window.OF = {
  onload: function(){
    if(!window.jQuery) return false;
    var pathname = location.pathname;
    if(1){
      if(pathname.match(/^\/rt\/Ticket\/Create.html/i)) this.RT.create();
      else if(pathname.match(/^\/C/)) this.RT.create();
      else if(pathname.match(/^\/rt\/Search\/Results.html/i)) this.RT.list();
      else if(pathname.match(/^\/rt\/Ticket\/Modify.html/i)) this.RT.modify();
      else if(pathname.match(/^\/rt\/Ticket\/Display.html/i)) this.RT.display();
      else if(pathname.match(/^\/viewvc/i)) this.viewvc();
      else if(pathname.match(/^\/websvn/i)) this.websvn();
      //else if(pathname.match(/^\/rt\/Search\/Results.html/i)) this.RT.create();
    }
    this.iframe_auto_height();
    //在iframe中就需改變link target
    if(parent != window){
      $("a[href*='http:']").attr("target","_top"); //external link
    }
    //不是openfoundry.org就加上ossf logo
    if(parent == window || this.is_crosssite() || !parent.location.host.match(location.host))
    {
      $("body").append('<a href="'+module.site_path+'" target="_blank"><img src="'+module.logo_path+'" style="border:none; float:right;"></a>');
    }
  },
  
  RT: {
    create: function(){
      $("input[name='Requestors'], input[name='Subject'], textarea[name='Content']").before('<span style="color:red">*</span>');
      if($("tr[id^='CF-']").length>0)
      {
        $("tr[id^='CF-']").parents("table:eq(1)").attr("id","CustomBlock").before('<a href="#" id="CustomSwitch">進階欄位(Advanced fields)</a>').hide();
        $("#CustomSwitch").click(function(){
          $("#CustomBlock").toggle("fast", function() {
            OF.iframe_auto_height();
          });	
        });
      }
      $("select").removeAttr("size");
      this.modify();
      $("form[name='TicketCreate']").validate({
        rules: {
          Requestors: {
            required: true,
            email: true
          },
          Subject: {
            required: true
          },
          Content: {
            required: true
          }
        },
        messages: {
          Requestors: "Please enter a valid email address"
        }
      });
    },//create end
    modify: function(){
      $("option[value='P1']").attr("text", "Most Important(P1)");
      $("option:contains('P2')").attr("text", "Important(P2)");
      $("option:contains('P3')").attr("text", "Normal(P3)");
      $("option:contains('P4')").attr("text", "Less Important(P4)");
      $("option:contains('P5')").attr("text", "Least Important(P5)");
    },//modify end 
    list: function(){
      $(".oddline").parent().children("tr:odd").children().attr("style", "border-bottom:solid 1px #006699;");
      $("small:empty").html('&nbsp;');//IE的empty-cells問題, 會沒有border.
      $("tr:has(small:contains('P1'))").attr("style", "background-color:#FF6F6F;").prev().css("background-color","#FF6F6F");
      $("tr:has(small:contains('P2'))").css("background-color","#FFAFAF").prev().css("background-color","#FFAFAF");
      $("tr:has(small:contains('P3'))").css("background-color","#FFE8BF").prev().css("background-color","#FFE8BF");
      $("tr:has(small:contains('P4'))").css("background-color","#F9AFFF").prev().css("background-color","#F9AFFF");
      $("tr:has(small:contains('P5'))").css("background-color","#F35FFF").prev().css("background-color","#F35FFF");
      $("tr").find("td:eq(2):contains('已處理'), td:eq(2):contains('已駁回'), td:eq(2):contains('rejected'), td:eq(2):contains('resolved')").parent().css("background-color","gray").next().css("background-color","gray");
      $("small:contains('P1')").css("background-color","#FF6F6F");
      $("small:contains('P2')").css("background-color","#FFAFAF");
      $("small:contains('P3')").css("background-color","#FFE8BF");
      $("small:contains('P4')").css("background-color","#F9AFFF");
      $("small:contains('P5')").css("background-color","#F35FFF");
    },//list end
    display: function(){
      $("a[title='Toggle visibility']").addClass().click(function(){
        OF.iframe_auto_height();
      });
      $(".titlebox:first").addClass("rolled-up");
      $(".titlebox-content:first").addClass("hidden");
    } //display end
  },//RT end
  
  Sympa: function(){
    return "Sympa";
  },//Sympa end
  
  kwiki: function(){
    return "kwiki";
  },//Kwiki end
  
  viewvc: function(){
    $("a[title^='ViewVC']").css("display", "none"); //ViewVC Logo
    if(parent != window){
      $("div.vc_navheader").css("display", "none"); //nav bar
    }
  },//viewvc end

  websvn: function(){
    if(parent != window){
      switch($("select[name='templatechoice']").val())
      {
        case 'BlueGrey':
          $("div#header, div#projects").css("display", "none");
          break;
        case 'calm':
          $("div#select, h1").css("display", "none");
          $("div#info").css({"width":"20%"});
          $("div#wrap").css({"width":"75%", "margin-left":"23%"});
          break;
        case 'Elegant':
          $("div#menus, h1").css("display", "none");
          break;
      }
      $("#templateform").insertAfter($("#revisionform"));
    }
  },//websvn end
  
  iframe_auto_height: function(){
    if(!this.in_of()) return;
    var iframe;
    $(parent.document).find("iframe").map(function(){
      if($(this).contents().get(0).location == window.location) iframe = this;
    });
    if(!iframe) return;//no parent
    var content_height = $("body").height()+50;
    content_height = content_height < 300 ? 300 : content_height; //set minimal height
    content_height = typeof content_height == 'number' ? content_height+"px" : content_height
    iframe.style.height = content_height;
  },//iframe_auto_height end
  
  in_of: function(){
    if(parent != window && this.is_crosssite() == false) return(true);
    return(false);
  },
  
  is_crosssite: function() {
    try {
      parent.location.host;
      return(false);
    }
    catch(e) {
      return(true);
    }
  }
};

} //OF Module end
