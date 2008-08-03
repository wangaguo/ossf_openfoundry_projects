class Job < ActiveRecord::Base
  belongs_to :project, :foreign_key => "project_id"
  STATUS = {:Enabled => 1, :Disabled => 0}

  #add fulltext indexed SEARCH
  acts_as_ferret({
                  :fields => { 
                              :subject => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :yes },
                              :description => { :store => :yes,
                                             :index => :yes },  
                              :requirement => { :store => :yes,
                                             :index => :yes }
                            },
                  :single_index => true,
                  :default_field => [:subject, :description, :requirement]
                 },{ :analyzer => GENERIC_ANALYZER })
  
  def should_be_indexed?
    self.status == Job::STATUS[:Enabled]
  end
  def ferret_enabled?(is_bulk_index = false)
    should_be_indexed? && #super(is_bulk_index) # TODO: super will cause recursive call..
      (@ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?))
  end
  def destroy_ferret_index_when_not_ready
    ferret_destroy if not should_be_indexed?
  end
  after_save :destroy_ferret_index_when_not_ready
  
  validates_length_of :subject, :within => 3..255, :too_long => _("Length range is ") + "3-255", :too_short => _("Length range is ") + "3-255"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  
  def validate
    date_pattern = /^(19|20)\d\d[- \/.](0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])$/
    errors.add(:due, "must be formatted YYYY-MM-DD or YYYY/MM/DD") if
    due.nil? || date_pattern !~ due_before_type_cast
  end
  
  def self.AllProjectLatestJobs
    Job.find(:all, :joins => :project, 
              :conditions => ["jobs.due > getdate() and jobs.status = #{Job::STATUS[:Enabled]} and #{Project.in_used_projects("true", :alias => "projects")}"], 
              :order => "jobs.updated_at desc", :limit => 5
              )
  end
end
