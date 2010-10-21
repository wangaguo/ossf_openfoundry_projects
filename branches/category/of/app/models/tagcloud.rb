class Tagcloud < ActiveRecord::Base
	# category association
  has_many :projects, :foreign_key => :category
	# tagcloud association 
	has_and_belongs_to_many :tagged_projects, 
                       	  :class_name => 'Project',
												  :join_table => :tagclouds_projects, 
												  :association_foreign_key => :project_id, 
													:foreign_key => :tagcloud_id
	has_many :tagcloudsprojects, :foreign_key => :tagcloud_id

	# set tagcloud default values before saving
	before_save :default_values

  # definitions for status flags
  TYPE = { :TAG => 0, :CATEGORY => 1 }.freeze
  STATUS = { :PENDING => 0, :READY => 1 }.freeze
  
	# update amount of tags with tagclouds_projects model changing ( call by tagclouds_projects model )
	def update_count( update_data_id, mod_count )
		Tagcloud.update_counters update_data_id, :tagged => mod_count
	end

	# increase tag if it is searched
	def self.increase_searched_tag( tagname )
		tag = self.find( :first, :conditions => { :name => tagname } )
		unless tag.nil?
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
end
