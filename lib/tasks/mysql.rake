namespace :db do
  desc "mysqladmin -u root drop \#{the_db}; mysql -u root -e 'create database \#{the_db} default character set utf8 collate utf8_general_ci'"
  require "pp"
  task :recreate_db => :environment do
    abcs = ActiveRecord::Base.configurations

    # {"development"=>
    #   {"socket"=>"/var/run/mysqld/mysqld.sock",
    #    "username"=>"root",
    #    "adapter"=>"mysql",
    #    "password"=>nil,
    #    "database"=>"killme_development"},
    #  "production"=>
    #   {"socket"=>"/var/run/mysqld/mysqld.sock",
    #    "username"=>"root",
    #    "adapter"=>"mysql",
    #    "password"=>nil,
    #    "database"=>"killme_production"},
    #  "test"=>
    #   {"socket"=>"/var/run/mysqld/mysqld.sock",
    #    "username"=>"root",
    #    "adapter"=>"mysql",
    #    "password"=>nil,
    #    "database"=>"killme_test"}}

    #pp abcs
    
    case abcs[RAILS_ENV]["adapter"]
      when "mysql"
        the_db = abcs[RAILS_ENV]["database"]
        the_cmd = "mysqladmin -u root drop #{the_db}; mysql -u root -e 'create database #{the_db} default character set utf8 collate utf8_general_ci'"
	puts the_cmd
	sh the_cmd
    end
  end
end
