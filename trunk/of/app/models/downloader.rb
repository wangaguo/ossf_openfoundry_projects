class Downloader < ActiveRecord::Base
  belongs_to :fileentity
  belongs_to :user
  belongs_to :release
  belongs_to :project
  def check_mandatory(resource)#TODO impl!
    return true
  end
end
