class TagcloudsProject < ActiveRecord::Base
	# tagcloud association
	belongs_to :project, :foreign_key => :project_id
	belongs_to :tagcloud, :foreign_key => :tagcloud_id

  # re-count tagclouds after tagclouds_projects table changing
	after_save :increase_tagcloud_count
	after_destroy :decrease_tagcloud_count

  # increase the count when the tag is tagged
  def increase_tagcloud_count
    if tc = Tagcloud.find_by_id( self.tagcloud_id )
      tc.tagged += 1
      tc.save
    end
	end

  # decrease the count when the tag is un-tagged
	def decrease_tagcloud_count
    if tc = Tagcloud.find_by_idi( self.tagcloud_id )
      tc.tagged -= 1
    
      # clear the searched count if a tag is not tagged by any project
      # prevent someone to gain the search hits!!
      tc.searched = 0 if tc.tagged == 0

      tc.save
    end
	end
end
