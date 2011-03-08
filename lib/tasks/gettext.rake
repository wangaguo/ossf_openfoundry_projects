#desc "Create mo-files for L10n"
#task :makemo do
#    require 'gettext_rails/tools'
#      GetText.create_mofiles(true)
#end

#desc "Update pot/po files to match new version."
#task :updatepo do
#    require 'gettext_rails/tools'
#      GetText.update_pofiles("openfoundry", Dir.glob("{app,lib,bin}/**/*.{rb,rhtml,erb}"),
#                                                      "openfoundry 0.1")
#end
desc "Update pot/po files."
task :updatepo do
  require 'gettext_rails/tools'  #HERE!
  GetText.update_pofiles("openfoundry", Dir.glob("{app,lib,bin}/**/*.{rb,erb,rhtml}"), "openfoundry 0.1")
end

desc "Create mo-files"
task :makemo do
  require 'gettext_rails/tools'  #HERE!
  Locale.default="zh_TW"
  GetText.create_mofiles(true)
end

