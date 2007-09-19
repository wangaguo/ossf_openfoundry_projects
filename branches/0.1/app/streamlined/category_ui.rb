module CategoryAdditions

end
Category.class_eval {include CategoryAdditions}

class CategoryUI < Streamlined::UI
	user_columns :name, {:human_name => '分類名稱'}, 
		     :supercategory, {:human_name => '上層分類'},
                     :description, {:human_name => '描述'}
end   
