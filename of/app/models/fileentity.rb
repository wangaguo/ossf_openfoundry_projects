class Fileentity < ActiveRecord::Base
  belongs_to :release
  has_one :survey 
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
  def self.published_files(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  named_scope :active, :conditions => ['status = 1']
  named_scope :inactive, :conditions => ['status = 0']
end
