// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function SetLang(lang)
{
  var langHref = "";
  langHref = location.search.replace(/[&|?]lang=[^&]*/,'').replace(/^[&|?]*/,'');
  if(langHref == "") langHref += "?";
  else langHref = "?" + langHref + "&";
  location.href =  location.href.replace(/\?.*/,'') + langHref + "lang=" + lang;
}

function submenuSwitch(item)
{ 
	var submenu = item.nextSibling;
  while (submenu.nodeType!=1) submenu=submenu.nextSibling;
	if(submenu.style.display == 'none') submenu.style.display = 'block';
	else submenu.style.display = 'none';
}