class News < ActiveRecord::Base
  belongs_to :project, :foreign_key => "catid"
  
  STATUS = {:Enabled => 1, :Disabled => 0}
  #add fulltext indexed SEARCH
  acts_as_ferret({
                  :fields => { 
                              :subject => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :yes },
                              :description_without_tag => { :store => :yes,
                                             :index => :yes }                                                         
                            },
                  :single_index => true
                 },{ :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD })
  def description_without_tag
    description.gsub(/<[^>]*>/, '')
  end

  def should_be_indexed?
    self.status == News::STATUS[:Enabled]
  end
  def ferret_enabled?(is_bulk_index = false)
    should_be_indexed? && #super(is_bulk_index) # TODO: super will cause recursive call..
      (@ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?))
  end
  def destroy_ferret_index_when_not_ready
    ferret_destroy if not should_be_indexed?
  end
  after_save :destroy_ferret_index_when_not_ready
  
  validates_length_of :subject, :within => 3..100, :too_long => _("Length range is ") + "3-100", :too_short => _("Length range is ") + "3-100"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  validates_exclusion_of :updated_at, :in => [nil], :message => _("is an invalid datetime")
  def self.home_news
    News.find(:all, :conditions => ["catid=0 and status = #{News::STATUS[:Enabled]}"], :order => "updated_at desc", :limit => 5)
  end
  
  def self.ProjectNews
    News.find(:all, :joins => :project, 
              :conditions => ["catid<>0 and news.status = #{News::STATUS[:Enabled]} and #{Project.in_used_projects(:alias => 'projects')}"], 
              :order => "news.updated_at desc", :limit => 5
              )
  end
  
end
