class Fileentity < ActiveRecord::Base
  belongs_to :release
  has_one :survey 
  #redis counter settings
  acts_as_redis_counter :file_counter, :ttl => 5.minutes, :hits => 100
  def self.published_files(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  scope :active, :conditions => ['status = 1']
  scope :inactive, :conditions => ['status = 0']
end
