<!-- Place in iframe content html file by wangaguo-->
<!--
//include jquery.js
document.write("<" + "script src=\"/javascripts/jquery.js\"></" + "script>");
function init()
{
  if(parent.document.getElementById("of_module"))
    parent.document.getElementById("of_module").style.height = this.document.body.scrollHeight+50+"px";
  multi_lang();
  $("a[href*='http:']").attr("target","_top");
}

if(window.attachEvent)
{
  window.attachEvent("onload",  init);
}
else if(window.addEventListener)
{
  window.addEventListener('load',  init,  false);
}

function multi_lang()
{
  //get current language, default is zh_TW
  var $l = parent.document.getElementById("lang")? parent.document.getElementById("lang").value : "en";
  //language resource
  var $r = 
  {
    help: {en: "Help", zh_TW: "說明"},
    help_url: {en: "/kwiki/openfoundry/index.cgi?KwikiFormattingRules", zh_TW: "/kwiki/openfoundry/index.cgi?%E5%BF%AB%E7%B4%80%E6%96%87%E5%AD%97%E6%A0%BC%E5%BC%8F%E8%AA%9E%E6%B3%95"},
    page_privacy: {en: "Page Privacy", zh_TW: "本頁隱私"},
    public: {en: "Public", zh_TW: "公開"},
    protected: {en: "Protected", zh_TW: "保護"},
    private: {en: "Private", zh_TW: "私有"},
    home: {en: "Home", zh_TW: "首頁"},
    changes: {en: "Changes", zh_TW: "最近更動"},
    edit: {en: "Edit", zh_TW: "編輯"},
    revisions: {en: "Revisions", zh_TW: "修訂記錄"},
    list_pages: {en: "List Pages", zh_TW: "頁面列表"},
    previous: {en: "Previous", zh_TW: "上一版"},
    current: {en: "Current", zh_TW: "目前版本"},
    next: {en: "Next", zh_TW: "下一版"},
    differences: {en: "Differences", zh_TW: "比較差異"},   
    enter_the_code: {en: "Please enter the code as seen in the image above to post your comment.", zh_TW: "請輸入上方圖片中的文字再送出文件。"}
  };
  //start convert
  ts = $(".widgets").html();
  ts = ts.replace(/Page Privacy/, $r.page_privacy[$l]);
  ts = ts.replace(/Public/, $r.public[$l]);
  ts = ts.replace(/Protected/, $r.protected[$l]);
  ts = ts.replace(/Private/, $r.private[$l]);
  $(".widgets").html(ts);
  $(".toolbar").append("&nbsp<a href=\"" + $r.help_url[$l] + "\" target=\"_blank\">" + $r.help[$l] + "</a>");
  $(".toolbar>a:contains('Home')").html($r.home[$l]);
  $(".toolbar>a:contains('Changes')").html($r.changes[$l]);
  $(".toolbar>a:contains('Edit')").html($r.edit[$l]);
  $(".toolbar>a:contains('Revisions')").html($r.revisions[$l]);
  $(".toolbar>a:contains('List Pages')").html($r.list_pages[$l]);
  $(".toolbar>a:contains('Previous')").html($r.previous[$l]);
  $(".toolbar>a:contains('Current')").html($r.current[$l]);
  $(".toolbar>a:contains('Next')").html($r.next[$l]);
  $(".toolbar>a:contains('Differences')").html($r.differences[$l]);
  $("p.description:contains('Please enter the code')").html("<em style=\"color:red;font-style:normal;\">" + $r.enter_the_code[$l] + "</em>");
}

//-->
