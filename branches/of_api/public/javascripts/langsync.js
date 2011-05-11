if(!$sso) var $sso = {};

(function(sso){
  sso.langCookies = {openfoundry:'oflang', wsw:'jfcookie[lang]'};
  sso.langs = {en:'en', zh_TW:'zh_TW', tw:'zh_TW'}; 
  
  sso.createCookie = function(name,value,days) {
    var expires = '';
    if (days) {
      var date = new Date();
      date.setTime(date.getTime()+(days*24*60*60*1000));
      expires = "; expires="+date.toGMTString();
    }
    document.cookie = name+"="+value+expires+"; path=/";
  };

  sso.getLang = function() {
    var lang = '';
    lang = location.search.match(/[&|?]lang=([^&]*)/,'');
    if(!lang) lang=""; else lang=lang[1]; 
    for (var l in this.langs)
    {
      if(location.pathname.match("^/"+l+"(/|$)")) return(this.langs[l]);
      if(lang == l) return(this.langs[l]); 
    }
    return(""); 
  };
  
  sso.langSync = function(lang) {
    if(!this.langs[lang]) return(0);

    for (var l in this.langCookies)
    {
      this.createCookie(this.langCookies[l], lang, '');
    }
    return(1);
  };
  
  sso.langAutoSync = function() {
    this.langSync(this.getLang());
  };
})($sso);

$sso.langAutoSync();
