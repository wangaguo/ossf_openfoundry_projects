namespace :gettext do
  def load_gettext
    #require 'gettext'
    require 'gettext/utils'
    #require 'gettext/tools'
  end

  desc "Create mo-files for L10n"
  task :pack do
    load_gettext
    Locale.set_current('zh_TW','en') 
    GetText.create_mofiles_org(:po_root => "po", :mo_root =>"locale")
  end

  desc "Update pot/po files."
  task :find do
    load_gettext
    $LOAD_PATH << File.join(File.dirname(__FILE__),'..','lib')
    require 'gettext_i18n_rails/haml_parser'

    GetText.update_pofiles_org(
      "openfoundry",
      Dir.glob("{app,lib,config}/**/*.{rb,erb,haml,rhtml}"),
      "version 0.0.1",
      :po_root => 'po',
      :msgmerge => [:sort_output]  )
  end

  # This is more of an example, ignoring
  # the columns/tables that mostly do not need translation.
  # This can also be done with GetText::ActiveRecord
  # but this crashed too often for me, and
  # IMO which column should/should-not be translated does not
  # belong into the model
  #
  # You can get your translations from GetText::ActiveRecord
  # by adding this to you gettext:find task
  #
  # require 'activerecord'
  # gem "gettext_activerecord", '>=0.1.0' #download and install from github
  # require 'gettext_activerecord/parser'
  desc "write the locale/model_attributes.rb"
  task :store_model_attributes => :environment do
    FastGettext.silence_errors
    require 'gettext_i18n_rails/model_attributes_finder'
    storage_file = 'locale/model_attributes.rb'
    puts "writing model translations to: #{storage_file}"
    GettextI18nRails.store_model_attributes(
      :to=>storage_file,
      :ignore_columns=>[/_id$/,'id','type','created_at','updated_at'],
      :ignore_tables=>[/^sitemap_/,/_versions$/,'schema_migrations']
    )
  end

  desc 'tries to install gettext from git'
  task :install do
    lib,version = 'gettext','2.0.0'
    begin
      gem lib, ">=#{version}"
      puts "#{lib} version >=#{version} exists!"
    rescue LoadError
      #check if locale gem is installed, since gettext install will fail without it
      begin
        require 'locale'
      rescue LoadError
        puts "first install locale gem: sudo gem install locale"
        exit
      end

      #install by checking out from github
      puts "installing #{lib}...."
      raise "a folder named #{lib} already exists, aborting!!" if File.exist?(lib)
      `git clone git://github.com/mutoh/#{lib}.git`
      `cd #{lib} && rake gem`
      `sudo gem install #{lib}/pkg/#{lib}*.gem`
      `rm -rf #{lib}`
    end
  end
end
