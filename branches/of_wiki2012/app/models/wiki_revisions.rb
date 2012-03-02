class WikiRevisions < ActiveRecord::Base
  belongs_to :page, :class_name => 'WikiPages', :foreign_key => 'page_id'
end
