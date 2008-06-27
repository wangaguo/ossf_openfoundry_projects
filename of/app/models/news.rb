class News < ActiveRecord::Base
  STATUS = {:Enabled => 1, :Disabled => 0}
  
  validates_length_of :subject, :within => 3..100, :too_long => _("Length range is ") + "3-100", :too_short => _("Length range is ") + "3-100"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  validates_date_time :updated_at, :message => _("Not a valid date time"), :allow_nil => true
  
  def self.home_news
    News.find(:all, :conditions => ['catid="0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
  def self.ProjectNews
    News.find(:all, :conditions => ['catid<>"0" and status = "1"'], :order => "updated_at desc", :limit => 5)
  end
  
end
