require "json"
class SiteAdmin::TagsController < SiteAdmin

  def create
    if request.post?
      new(params[:tag_new_name], params[:tag_status], params[:tag_type]) unless params[:tag_new_name].blank?
      redirect_to "#{root_path}/site_admin/admin/manage_tags"
    end
  end

  def edit
    if request.post?
      update(params[:tag_old_name], params[:tag_new_name], params[:tag_status], params[:tag_type]) unless params[:tag_new_name].blank?
      redirect_to "#{root_path}/site_admin/admin/manage_tags"
    end
  end

  def delete
    if request.post?
      params[:tag_id].split(",").each{ |tid| destroy(tid.strip) }
      session[:tmsg] = "Deleted."
    end
  end

  def fetch()
    if request.post?
      begin
        t = Tagcloud.find_by_id(params[:tag_id]) unless params[:tag_id].empty?
        data =  {:id => t.id, :name => t.name, :type => t.tag_type, :status => t.status}
        render :json => data.to_json; return
      rescue
        render :text => 'Error, no such tag'; return
      end
    end
  end

  def ready
    if request.post?
      params[:tag_id].split(",").each do |tid| 
        @ready_tag = Tagcloud.find_by_id(tid)
        @ready_tag.status = 1 if @ready_tag.status == 0
        @ready_tag.save
      end
      session[:tmsg] = "Ready Ok!"
    end
  end

  def pending
    if request.post?
      params[:tag_id].split(",").each do |tid| 
        @pending_tag = Tagcloud.find_by_id(tid)
        @pending_tag.status = 0 if ( @pending_tag.status == 1 && @pending_tag.tag_type == 0 )
        @pending_tag.save
      end
      session[:tmsg] = "Pending Ok! (But category could not be pending.)"
    end
  end

  def new(tname, tstatus, ttype) 
    if Tagcloud.find_by_name(real_title(tname)).nil?
      @new_tag = Tagcloud.new
      @new_tag.name = real_title(tname)
      @new_tag.tag_type = ttype.strip
      @new_tag.status = tstatus.strip
      session[:ided] = "#{@new_tag.id.to_s}" if @new_tag.save
      session[:tmsg] = "'#{tname}' added."
    else
      session[:tmsg] = "#{tname} was already exists."
    end
  end

  def update(oldname, newname, newstatus, newtype)
    @tag = Tagcloud.find_by_name( oldname )
    unless @tag.nil?
      @tag.name = newname if Tagcloud.find_by_name( newname ).nil?
      @tag.status = newstatus.strip
      @tag.tag_type = newtype.strip
      session[:ided] = "#{@tag.id.to_s}" if @tag.save
      session[:tmsg] = "Updated."
    end
  end

  protected
  def destroy(tid)
    t = Tagcloud.find_by_id( tid )
    t.destroy if t
  end

end
