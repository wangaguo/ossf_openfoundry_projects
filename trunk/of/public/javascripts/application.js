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

function project_menu()
{
  $('project_admin_menu').style.display = "none";
}

function project_leftmenu_onclick(tab)
{
  if (tab == 1) {
    $('project_menu').style.display = "block";
    $('project_admin_menu').style.display = "none";
  }
  else
  {
    $('project_menu').style.display = "none";
    $('project_admin_menu').style.display = "block";
  }
}
