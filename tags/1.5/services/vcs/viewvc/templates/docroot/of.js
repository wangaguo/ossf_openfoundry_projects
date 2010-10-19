function OF_INIT()
{
	if(parent.document.getElementById("VCS"))
	{
		parent.document.getElementById("VCS").style.height = this.document.body.scrollHeight+50+"px";
		if(document.getElementById("vc_navheader")) document.getElementById("vc_navheader").style.display = "none";
	}
}

if(window.attachEvent)
{
	window.attachEvent("onload",  OF_INIT);
}
else if(window.addEventListener)
{
	window.addEventListener('load',  OF_INIT,  false);
}
