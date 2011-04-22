class Fileentity < ActiveRecord::Base
  belongs_to :release
  has_one :survey 
  #redis counter settings
  #acts_as_redis_counter :file_counter, :ttl => 5.minutes, :hits => 100
  def counter
    @counter ||= Counter.find(:item_id => self.id, :item_class => 'Fileentity').first
    if @counter.nil?           
      @counter = Counter.create(:item_id => self.id,
                                :item_class => 'Fileentity',
                                :item_counter_attribute => 'file_counter',
                                :flushed_at => Time.now.to_i)   
      @counter.incr(:counter, self.file_counter)             
    end
    @counter
  end 

#  #add fulltext indexed SEARCH
#  acts_as_ferret({
#                 :fields => { 
#                              :name => { :boost => 1.5,
#                                          :store => :yes },
#                              :description => { :store => :yes}
#                            },
#                 :single_index => true
#                 },{ :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD } )          
  def self.published_files(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  scope :active, :conditions => ['status = 1']
  scope :inactive, :conditions => ['status = 0']
end
