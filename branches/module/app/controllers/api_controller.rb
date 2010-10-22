class ApiController < ApplicationController
  def get
    resources = parse_resources 
    ids = parse_ids
    
    dataset = parse_dataset
    if dataset
      @found = resources.valid.find ids, :select => dataset.columns
      render :text => @found.to_json
    else
      render :text => "no dataset found! debug: "+params.inspect
    end
  end
  
  def sync
    resources = parse_resources 
    period = parse_period
    
    dataset = parse_dataset 
    if dataset
      @found = resources.valid.find :all, :select => dataset.columns, 
      	:conditions => ["updated_at > ?", period],
	:order => "updated_at DESC"
      render :text => @found.to_json
    else
      render :text => "no dataset found! debug: "+params.inspect
    end
  end

  def user
    case params[:do]
    
    when 'partners' then
      @user = User.find_by_login params[:name] 
      @partners = User.find_by_sql("select distinct(U.id),U.icon,U.login from users U join roles_users RU join roles R join roles R2 join roles_users RU2 where U.id = RU.user_id and RU.role_id = R.id and R.authorizable_id = R2.authorizable_id and R.authorizable_type = 'Project' and R2.authorizable_type = 'Project' and RU2.role_id = R2.id and RU2.user_id =#{@user.id} and U.id != #{@user.id} order by U.id") if @user
    when 'projects' then
      @user = User.find_by_login params[:name]
      @projects = Project.find_by_sql("select distinct(P.id),P.icon,P.name from projects P join roles R join roles_users RU where P.id = R.authorizable_id and R.authorizable_type = 'Project' and R.id = RU.role_id and RU.user_id = #{@user.id} and #{Project.in_used_projects(:alias => 'P')} order by P.id") if @user
    else
      
    end  
    api_render
  end

  def project
    
  end
  private
  def parse_dataset
    DataSet.find_by_model params[:resources]
  end
 
  def parse_resources
    params[:resources].camelize.singularize.constantize
  end

  def parse_ids
    ids = params[:ids]
    #TODO handle resources that take name as primary-key
    case ids
      #empty = get all resources
      when nil then :all
      #only one resource
      when /^\d+$/ then ids
      #1,2,3,4,5 => make it [1,2,3,4,5]
      when /^\d+,\d+(,\d+)*$/ then ids.split(',')	    
      #sorry, no such id, just give not-found
      else raise ActiveRecord::RecordNotFound	    
    end  
  end
 
  def parse_period
    n = params[:number]
    if n 
      # give xxx (y/d/h/m) ago	    
      n.to_i.send(params[:period_type]).ago
    elsif params[:year]
      #TODO handle timezone, system is UTC
      # give a datetime
      DateTime.civil(
         params[:year].to_i,
	#no zero-month 
        (params[:month]||1).to_i,
        #no zero-day
	(params[:day]||1).to_i,
        (params[:hour]||0).to_i,
	(params[:minute]||0).to_i,0,0
      )	
    else 
      0
    end  
  end

  def api_render
    render :file => "api/#{params[:do]}", :layout =>false 
  end
end
