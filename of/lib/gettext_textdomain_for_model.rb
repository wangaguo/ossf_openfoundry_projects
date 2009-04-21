#init fase_gettext
FastGettext.add_text_domain 'openfoundry', :path => File.join(RAILS_ROOT, 'locale')  

#enable gettext for ActiveRecord::Base
#ActiveRecord::Base.send(:include, FastGettext::Translation)
#ActiveRecord::Base.class_eval(" 
#    FastGettext.available_locales = ['en', 'zh_TW']
#    FastGettext.text_domain = 'openfoundry'
#"                              
#)
