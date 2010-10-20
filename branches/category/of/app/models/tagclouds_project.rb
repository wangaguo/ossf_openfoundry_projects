class TagcloudsProject < ActiveRecord::Base
	# tagcloud association
	belongs_to :project, :foreign_key => :project_id
	belongs_to :tagcloud, :foreign_key => :tagcloud_id

	# re-count tagclouds by tagclouds_projects table changing
	after_save :increase_tagcloud_count
	after_destroy :decrease_tagcloud_count

	# call the method in the tagclouds model to change the tagged field ( amount of tags ) in tagclouds table
	# here CANNOT combine to one method ( increase, decrease ) !!
  def increase_tagcloud_count
		tagcloud.update_count self.tagcloud_id, 1
	end

	def decrease_tagcloud_count
	 	tagcloud.update_count self.tagcloud_id, -1	
	end
end
