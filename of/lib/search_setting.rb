class User < ActiveRecord::Base
  #add fulltext indexed SEARCH
  acts_as_ferret({
                 :fields => {:login => {:boost => 1.5,:store => :yes}#, 
                             #:firstname => {:boost => 0.8,:store => :yes}, 
                             #:lastname => {:boost => 0.8,:store => :yes}, 
                             #:name => {:boost => 0.8,:store => :yes} 
                            },
                 :single_index => true,
                 :default_field => [:login, :firstname, :lastname, :name]
                 }, { :analyzer => GENERIC_ANALYZER } )
                 
  # disable ferret search if not verified        
  def ferret_enabled?(is_bulk_index = false)
    (verified == 1) && @ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?)
  end
end
class Project < ActiveRecord::Base
end
class News < ActiveRecord::Base
  #add fulltext indexed SEARCH
  acts_as_ferret({
                  :fields => { 
                              :subject => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :yes },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
                  :single_index => true,
                  :default_field => [:subject, :description]
                 },{ :analyzer => GENERIC_ANALYZER })
  
end
class Release < ActiveRecord::Base
  #add fulltext indexed SEARCH
  acts_as_ferret({ :fields => { 
                              :name => { :boost => 1.5,
                                          :store => :yes
                                          },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
                 :single_index => true,
                 :default_field => [:name, :description]
                 },{ :analyzer => GENERIC_ANALYZER })
  
end
