class Fileentity < ActiveRecord::Base
  belongs_to :release
  
  #add fulltext indexed SEARCH
  acts_as_ferret({
                 :fields => { 
                              :name => { :boost => 1.5,
                                          :store => :yes },
                              :description => { :store => :yes}
                            },
                 :single_index => true,
                 :default_field => [:name, :description]
                 },{ :analyzer => GENERIC_ANALYZER } )          
end
