class Downloader < ActiveRecord::Base
  belongs_to :fileentity
  belongs_to :user
  belongs_to :release
  belongs_to :project
  def check_mandatory(resource)
    Downloader.content_columns.each_with_index do |col,i| 
      next if ['creator', 'updated_at', 'created_at', 'updated_by'].include? col.name
      if self.send(col.name).blank? and resource[i] == 50 #mandatory
        return false
      end
    end
    return true
  end

  scope :file_reviews, (
    lambda { |pid, r_version, f_path|
    {
      :include => [:release, :fileentity],
      :conditions => [ 'downloaders.project_id = ? and releases.version = ? and fileentities.path = ?',
       pid, r_version, f_path ]}
    }
    )
  scope :release_reviews, (
    lambda { |pid, r_version|
    {
      :include => :release,
      :conditions => [ 'downloaders.project_id = ? and releases.version = ?', pid, r_version ]}
    }
  )
  scope :project_reviews, (
    lambda { |pid|
    {:conditions => [ 'project_id = ?', pid ]}
    }
  )
  scope :recent, lambda{|ago| {:conditions => ['updated_at > ?', ago||1.day.ago] }}
end
