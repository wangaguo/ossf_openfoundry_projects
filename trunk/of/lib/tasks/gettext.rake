desc "Update pot/po files."
task :updatepo do
  require 'gettext/utils'
  GetText.update_pofiles("openfoundry", Dir.glob("{app,lib,bin}/**/*.{rb,rhtml}"), "openfoundry 0.1")
end
  
desc "Create mo-files"
task :makemo do
  require 'gettext/utils'
  GetText.create_mofiles(true, "po", "locale")
end
