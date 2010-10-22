class Fileentity < ActiveRecord::Base
  belongs_to :release
  has_one :survey 
  #redis counter settings
  acts_as_redis_counter :file_counter, :ttl => 5.minutes, :hits => 100
  #add fulltext indexed SEARCH
  #acts_as_ferret({
  #               :fields => { 
  #                            :name => { :boost => 1.5,
  #                                        :store => :yes },
  #                            :description => { :store => :yes}
  #                          },
  #               :single_index => true
  #               },{ :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD } )          
  def self.published_files(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  named_scope :active, :conditions => ['status = 1']
  named_scope :inactive, :conditions => ['status = 0']
end
