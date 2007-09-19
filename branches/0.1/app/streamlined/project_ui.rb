module ProjectAdditions
	def projectmembers
		return ( self.admins.collect{|x| x.login } +
                        self.members.collect{|x| x.login } ).join ','
	end 
end
Project.class_eval {include ProjectAdditions}

class ProjectUI < Streamlined::UI
	user_columns :unixname, {:human_name => '專案代碼',:read_only => true },
                     :projectname, {:human_name => '專案名稱'}, 
                     :publicdescription, {:human_name => '專案描述'},
                     :platform, {:human_name => '操作平台',:enumeration => Project::PLATFORMS },
		     :license, {:enumeration => Project::LICENSES, :unassigned_value => 'unknown license' },
		     :programminglanguage, {:human_name => '撰寫語言', :enumeration => Project::PROGRAMMING_LANGUAGES },
		     :projectmembers, {:human_name => '專案成員'}#, :show_view => [:name]}
end   
