// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function SetLang(lang)
{
  var langHref = "";
  langHref = location.search.replace(/[&|?]lang=[^&]*/,'').replace(/^[&|?]*/,'');
  if(langHref == "") langHref += "?";
  else langHref = "?" + langHref + "&";
  location.href =  location.protocol + "//" + location.host + location.pathname + langHref + "lang=" + lang + location.hash;
}

function submenuSwitch(item)
{ 
	var submenu = item.nextSibling;
  while (submenu.nodeType!=1) submenu=submenu.nextSibling;
	if(submenu.style.display == 'none') submenu.style.display = 'block';
	else submenu.style.display = 'none';
}

function project_leftmenu_onclick(tab)
{
  if(tab == 2 && $('project_admin_menu') != null) 
  {
    $('project_menu').style.display = "none";
    if($('project_admin_menu') != null) $('project_admin_menu').style.display = "block";
  }
  else
  {
    $('project_menu').style.display = "block";
    if($('project_admin_menu') != null) $('project_admin_menu').style.display = "none";
  }
  setCookie("project_leftmenu_state", tab,"","/");
}

function project_leftmenu_init()
{
  project_leftmenu_onclick(getCookie("project_leftmenu_state"));
}

/*
   name - name of the cookie
   value - value of the cookie
   [expires] - expiration date of the cookie
     (defaults to end of current session)
   [path] - path for which the cookie is valid
     (defaults to path of calling document)
   [domain] - domain for which the cookie is valid
     (defaults to domain of calling document)
   [secure] - Boolean value indicating if the cookie transmission requires
     a secure transmission
   * an argument defaults when it is assigned null as a placeholder
   * a null placeholder is not required for trailing omitted arguments
*/

function setCookie(name, value, expires, path, domain, secure) {
  var curCookie = name + "=" + escape(value) +
      ((expires) ? "; expires=" + expires.toGMTString() : "") +
      ((path) ? "; path=" + path : "") +
      ((domain) ? "; domain=" + domain : "") +
      ((secure) ? "; secure" : "");
  document.cookie = curCookie;
}


/*
  name - name of the desired cookie
  return string containing value of specified cookie or null
  if cookie does not exist
*/

function getCookie(name) {
  var dc = document.cookie;
  var prefix = name + "=";
  var begin = dc.indexOf("; " + prefix);
  if (begin == -1) {
    begin = dc.indexOf(prefix);
    if (begin != 0) return null;
  } else
    begin += 2;
  var end = document.cookie.indexOf(";", begin);
  if (end == -1)
    end = dc.length;
  return unescape(dc.substring(begin + prefix.length, end));
}


/*
   name - name of the cookie
   [path] - path of the cookie (must be same as path used to create cookie)
   [domain] - domain of the cookie (must be same as domain used to
     create cookie)
   path and domain default if assigned null or omitted if no explicit
     argument proceeds
*/

function deleteCookie(name, path, domain) {
  if (getCookie(name)) {
    document.cookie = name + "=" +
    ((path) ? "; path=" + path : "") +
    ((domain) ? "; domain=" + domain : "") +
    "; expires=Thu, 01-Jan-70 00:00:01 GMT";
  }
}

// date - any instance of the Date object
// * hand all instances of the Date object to this function for "repairs"

function fixDate(date) {
  var base = new Date(0);
  var skew = base.getTime();
  if (skew > 0)
    date.setTime(date.getTime() - skew);
}

function HeaderOnOff(vSwitch)
{
	var vSwitch = getCookie("HeaderOnOff");
	if(vSwitch == 'OFF' )
	{
		//open
		setCookie("HeaderOnOff", "ON","","/");
		$("header").style.display = "block";
    $('HeaderOnOffImage').src="/images/HeaderOnOff_Off.gif";
	}
	else
	{
		//Close
		setCookie("HeaderOnOff", "OFF","","/");
		$("header").style.display = "none";
    $('HeaderOnOffImage').src="/images/HeaderOnOff_On.gif";
	}
}

function wo(url) {
  return "javascript:var a = window.open('" + url + "')";
}
function grayOut(vis, options) {
  // Pass true to gray out screen, false to ungray
  // options are optional.  This is a JSON object with the following (optional) properties
  // opacity:0-100         // Lower number = less grayout higher = more of a blackout 
  // zindex: #             // HTML elements with a higher zindex appear on top of the gray out
  // bgcolor: (#xxxxxx)    // Standard RGB Hex color code
  // grayOut(true, {'zindex':'50', 'bgcolor':'#0000FF', 'opacity':'70'});
  // Because options is JSON opacity/zindex/bgcolor are all optional and can appear
  // in any order.  Pass only the properties you need to set.
  var options = options || {}; 
  var zindex = options.zindex || 50;
  var opacity = options.opacity || 70;
  var opaque = (opacity / 100);
  var bgcolor = options.bgcolor || '#000000';
  var dark=document.getElementById('darkenScreenObject');
  if (!dark) {
    // The dark layer doesn't exist, it's never been created.  So we'll
    // create it here and apply some basic styles.
    // If you are getting errors in IE see: http://support.microsoft.com/default.aspx/kb/927917
    var tbody = document.getElementsByTagName("body")[0];
    var tnode = document.createElement('div');           // Create the layer.
        tnode.style.position='absolute';                 // Position absolutely
        tnode.style.top='0px';                           // In the top
        tnode.style.left='0px';                          // Left corner of the page
        tnode.style.overflow='hidden';                   // Try to avoid making scroll bars            
        tnode.style.display='none';                      // Start out Hidden
        tnode.id='darkenScreenObject';                   // Name it so we can find it later
    tbody.appendChild(tnode);                            // Add it to the web page
    dark=document.getElementById('darkenScreenObject');  // Get the object.
  }
  if (vis) {
    // Calculate the page width and height 
    if( document.body && ( document.body.scrollWidth || document.body.scrollHeight ) ) {
        var pageWidth = document.body.scrollWidth+'px';
        var pageHeight = document.body.scrollHeight+'px';
    } else if( document.body.offsetWidth ) {
      var pageWidth = document.body.offsetWidth+'px';
      var pageHeight = document.body.offsetHeight+'px';
    } else {
       var pageWidth='100%';
       var pageHeight='100%';
    }   
    //set the shader to cover the entire page and make it visible.
    dark.style.opacity=opaque;                      
    dark.style.MozOpacity=opaque;                   
    dark.style.filter='alpha(opacity='+opacity+')'; 
    dark.style.zIndex=zindex;        
    dark.style.backgroundColor=bgcolor;  
    dark.style.width= pageWidth;
    dark.style.height= pageHeight;
    dark.style.display='block';                          
  } else {
     dark.style.display='none';
  }
}

function iframe_auto_height(fid)
{
  var iframe = $(fid);
  try
  {
    var content_height = iframe.contentWindow.document.body.offsetHeight+50;
    content_height = content_height < 300 ? 300 : content_height; //set minimal height
    content_height = typeof content_height == 'number' ? content_height+"px" : content_height;
    iframe.setStyle({height:content_height});
  }
  catch(e){}
}
