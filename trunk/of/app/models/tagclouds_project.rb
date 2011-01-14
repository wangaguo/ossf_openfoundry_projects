class TagcloudsProject < ActiveRecord::Base
	# tagcloud association
	belongs_to :project
	belongs_to :tagcloud

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
    if tc = Tagcloud.find_by_id( self.tagcloud_id )
      tc.tagged -= 1
    
      # clear the searched count if a tag is not tagged by any project
      # prevent someone to gain the search hits!!
      tc.searched = 0 if tc.tagged == 0

      tc.save
    end
	end

  # append tags to a project
  def self.append_tags_to_project( pid, tlist )
    # set regular expression for protecting write tags to DB 
    tg = tlist.split( ',' )
    tg = tg.map{ | v | v.downcase.squeeze( ' ' ).strip }.select{ | v | v =~ /^[#+.!a-zA-Z0-9 ]+$/ }.uniq

    tg.each{ | t |
      titlename = t.titleize
      tc = Tagcloud.find :first, :conditions => { :name => titlename }
      tid = nil
      if( tc.nil? )
        # new tag
        ntc = Tagcloud.new
        ntc.name = titlename
        ntc.tag_type = Tagcloud::TYPE[ :TAG ] 
        ntc.save

        tid = ntc.id
      else
        tid = tc.id
      end

      # build association between a project and tags
      tp = TagcloudsProject.new
      tp.project_id = pid
      tp.tagcloud_id = tid
      tp.save
    }
  end

  # delete all tags for a project
  def self.delete_project_alltags( pid )
    tgs = Project.find_by_id( pid ).alltags_without_check
    tgs.each{ | t |
      tid = Tagcloud.find_by_name( t.name ).id
      deltag = TagcloudsProject.find :first, :conditions => { :tagcloud_id => tid, :project_id => pid }
      deltag.destroy
    }
  end
end
