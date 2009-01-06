class Downloader < ActiveRecord::Base
  belongs_to :fileentity
  belongs_to :user
  belongs_to :release
  belongs_to :project
  def check_mandatory(resource)#TODO impl!
    return true
  end

  named_scope :file_reviews, (
    lambda { |pid, r_version, f_path|
    {
      :include => [:release, :fileentity],
      :conditions => [ 'downloaders.project_id = ? and releases.version = ? and fileentities.path = ?',
       pid, r_version, f_path ]}
    }
    )
  named_scope :release_reviews, (
    lambda { |pid, r_version|
    {
      :include => :release,
      :conditions => [ 'downloaders.project_id = ? and releases.version = ?', pid, r_version ]}
    }
  )
  named_scope :project_reviews, (
    lambda { |pid|
    {:conditions => [ 'project_id = ?', pid ]}
    }
  )
end
