class ApiController < ApplicationController
  def user
    case params[:do]
    when 'partners' then
      @user = User.find_by_login params[:name], 
        :include => [:roles]
      @partners = User.find_by_sql("select distinct(U.id),U.icon,U.login from users U join roles_users RU join roles R join roles R2 join roles_users RU2 where U.id = RU.user_id and RU.role_id = R.id and R.authorizable_id = R2.authorizable_id and R.authorizable_type = 'Project' and R2.authorizable_type = 'Project' and RU2.role_id = R2.id and RU2.user_id =#{@user.id} and U.id != #{@user.id} order by U.id") if @user
    else
      
    end  
    api_render
  end

  def project
  end

  def api_render
    render :file => "api/#{params[:do]}", :layout => 'no_frame'
  end
end
