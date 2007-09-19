class Category < ActiveRecord::Base
	has_one :supercategory, :class_name => 'Category', :foreign_key => 'parent' 
end
