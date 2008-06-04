class Fileentity < ActiveRecord::Base
  belongs_to :release
  
  #add fulltext indexed SEARCH
  acts_as_ferret :fields => { 
                              :name => { :boost => 1.5,
                                          :store => :no,
                                          :index => :untokenized },
                              :description => { :store => :no,
                                             :index => :yes }                                                         
                            }
end
