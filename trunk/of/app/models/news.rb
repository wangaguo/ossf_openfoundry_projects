class News < ActiveRecord::Base
  validates_numericality_of :status, :less_than_or_equal_to => 0
  
  #add fulltext indexed SEARCH
  acts_as_ferret :fields => { 
                              :subject => { :boost => 1.5,
                                          :store => :no,
                                          :index => :untokenized },
                              :description => { :store => :no,
                                             :index => :yes }                                                         
                            }
  
  def self.home_news
    News.find(:all, :conditions => ['catid="0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
  def self.ProjectNews
    News.find(:all, :conditions => ['catid<>"0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
end
