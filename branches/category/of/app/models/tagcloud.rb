class Tagcloud < ActiveRecord::Base
	# category association
  has_many :projects, :foreign_key => :category
	# tagcloud association 
	has_and_belongs_to_many :tagged_projects, 
                       	  :class_name => 'Project',
												  :join_table => :tagclouds_projects, 
												  :association_foreign_key => :project_id, 
													:foreign_key => :tagcloud_id
#	has_many :tagcloudsprojects, :foreign_key => :tagcloud_id

	# set tagcloud default values before saving
	before_save :default_values

  # definitions for status flags
  TYPE = { :TAG => 0, :CATEGORY => 1 }.freeze
  STATUS = { :PENDING => 0, :READY => 1 }.freeze

  # find all ready tags
  named_scope :readytags, :conditions => [ "status = ? AND tagged <> 0", STATUS[ :READY ] ]
  # find all category tags
  named_scope :onlycategory, :conditions => { :status => STATUS[ :READY ], :tag_type => TYPE[ :CATEGORY ] }, :order => 'id'

	# increase tag if it is searched
	def self.increase_searched_tag( tagname )
		tag = self.readytags.find( :first, :conditions => { :name => tagname } )
		unless tag.nil? || tag.tagged == 0  # CANNOT increase the search hits for a tag is not tagged!!
		  tag.searched += 1
			tag.save	
		end
	end

	# set default values for tagcloud AR object if some fields are nil
	def default_values
		self.status = 0 unless self.status
		self.tagged = 0 unless self.tagged
		self.searched = 0 unless self.searched
	end

  # evaluate the weight for all validated tags
  def self.all_tags_with_weight
    # select fields needed order by weight
    tags = self.readytags.map { | set | 
      { :id => set.id, 
        :name => set.name, 
        :tagged => set.tagged, 
        :weight => set.tagged * 0.6 + set.searched * 0.4 }
      }

    # normalize each weight for tags
    maxweight = tags.max_by { | set | set[ :weight ] }[ :weight ]
    tags.each { | set | set[ :weight ] /= maxweight }
  end

  # select the tags with the HEAD and LAST options
  def self.select_tags_with_weight
    # select options
    max_head_num = 3
    min_last_num = 3

    # order the tags with their weights
    tags = all_tags_with_weight.sort_by { | set | set[ :weight ] }

    # select tags with the options
    if tags.count <= max_head_num + min_last_num
      tags
    else
      tags[ 0..max_head_num - 1 ] + tags[ 0 - min_last_num..-1 ]
    end
  end

  # assign the font size for the tags of the tagcloud
  def self.tags_assign_font_size( options )
    # select font size
    max_font_size = 30
    min_font_size = 8 

    # select a tags sample
    tags = ( options == 'ALL' )? all_tags_with_weight : select_tags_with_weight

    # assign font size to selected tags and order by the tag name
    tags.map { | set |
      { :id => set[ :id ],
        :name => set[ :name ],
        :tagged => set[ :tagged ],
        :font => ( set[ :weight ] * ( max_font_size - min_font_size ) + min_font_size ).round
      }
    }.sort_by { | set | set[ :name ] }
  end

  # throw tags to memory cache
  def self.cachedtags
    Rails.cache.fetch( 'tmptags', :expires_in => 1.minute ) do
      Tagcloud.find :all, :conditions => { :status => STATUS[ :READY ] }
    end
  end
end
