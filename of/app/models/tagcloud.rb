class Tagcloud < ActiveRecord::Base
	# category association
  has_many :projects, :foreign_key => :category
	# tagcloud association 
	#has_and_belongs_to_many :tagged_projects, 
  #                     	  :class_name => 'Project',
	#											  :join_table => :tagclouds_projects, 
	#											  :association_foreign_key => :project_id, 
	#												:foreign_key => :tagcloud_id
  has_many :tagclouds_projects
  has_many :taged_projects, :through => :tagclouds_projects, :source => :project
#	has_many :tagcloudsprojects, :foreign_key => :tagcloud_id

	# set tagcloud default values before saving
	before_save :default_values
  # disconnect the relations before destroying tags
  before_destroy :break_relations

  # definitions for status flags
  TYPE = { :TAG => 0, :CATEGORY => 1 }.freeze
  STATUS = { :PENDING => 0, :READY => 1 }.freeze

  # find all ready tags
  scope :readytags, :conditions => [ "status = ? AND tagged <> 0", STATUS[ :READY ] ]
  # find all category tags
  scope :onlycategory, :conditions => { :status => STATUS[ :READY ], :tag_type => TYPE[ :CATEGORY ] }, :order => 'id'

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
      {
        :id => set.id, 
        :name => set.name, 
        :tagged => set.tagged, 
        :weight => set.tagged * 0.6 + set.searched * 0.4
      }
    }

    # normalize each weight for tags
    maxweight = tags.max_by { | set | set[ :weight ] }[ :weight ]
    tags.each { | set | set[ :weight ] /= maxweight }
  end

  # select the tags with the HEAD and LAST options
  def self.select_tags_with_weight( tsize )
    # random all tags 
    tags = all_tags_with_weight.sort_by { rand }

    # choose the header tags with optional size
    if tags.count <= tsize 
      tags
    else
      tags[ 0..tsize - 1 ]
    end
  end

  # assign the font size for the tags of the tagcloud
  def self.tags_assign_font_size( pickup )
    # font size optional range
    font_size_set = [ 10, 16, 22, 28 ]
    font_color_set = [ '#99bbff', '#55a8ff', '#004ea0', '#0088b5' ]

    # select a tags sample
    tags = ( pickup.to_i == 0 )? all_tags_with_weight : select_tags_with_weight( pickup.to_i )

    # assign font size to selected tags and order by the tag name
    tags.map { | set |
      {
        :id => set[ :id ],
        :name => set[ :name ],
        :tagged => set[ :tagged ],
        :font => font_size_set[ ( set[ :weight ] * ( font_size_set.length - 1 ) ).round ],
        :color => font_color_set[ ( set[ :weight ] * ( font_color_set.length - 1 ) ).round ]
      }
    }.sort_by { | set | set[ :name ] }
  end

  # throw tags to memory cache
  def self.cachedtags
    Rails.cache.fetch( 'tmptags', :expires_in => 1.hour ) do
      Tagcloud.find :all, :conditions => { :status => STATUS[ :READY ] }
    end
  end

  # disconnect the relations between projects and destroyed tags
  def break_relations
    # delete the relations between projects and tags
    # ( category is also be a kind of tags )
    dtp = TagcloudsProject.find :all, :conditions => { :tagcloud_id => self.id }
    dtp.each { | dp | dp.destroy } unless dtp.empty?

    # remove the categories of projects
    if self.tag_type == Tagcloud::TYPE[ :CATEGORY ]
      projs = Project.find :all, :conditions => { :category => self.id }
      projs.each { | p | p.category = nil; p.save }
    end
  end
end
