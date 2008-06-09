class News < ActiveRecord::Base
  validates_length_of :subject, :within => 3..100, :too_long => _("Length range is ") + "3-100", :too_short => _("Length range is ") + "3-100"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_numericality_of :status, :less_than_or_equal_to => 1, :message => _("Not a valid value")
  
  #add fulltext indexed SEARCH
  acts_as_ferret :fields => { 
                              :subject => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :yes },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
                  :single_index => true,
                  :default_field => [:subject, :description]
  
  def self.home_news
    News.find(:all, :conditions => ['catid="0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
  def self.ProjectNews
    News.find(:all, :conditions => ['catid<>"0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
end
