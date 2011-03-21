class Job < ActiveRecord::Base
  belongs_to :project, :foreign_key => "project_id"
  STATUS = {:Enabled => 1, :Disabled => 0}

  validates_length_of :subject, :within => 3..255, :too_long => _("Length range is ") + "3-255", :too_short => _("Length range is ") + "3-255"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  validates_date :due
  
  def self.AllProjectLatestJobs
    Job.find(:all, :joins => :project, 
              :conditions => ["jobs.due > getdate() and jobs.status = #{Job::STATUS[:Enabled]} and #{Project.in_used_projects("true", :alias => "projects")}"], 
              :order => "jobs.updated_at desc", :limit => 5
              )
  end
end
