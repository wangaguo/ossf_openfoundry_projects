require "json"
class SiteAdmin::TagsController < ApplicationController

  # testing NEW action view
  def create
    if request.post?
      new(params[:tag_new_name].strip, params[:tag_status], params[:tag_type])
      redirect_to "/of/site_admin/site_admin/manage_tags"
    end
  end

  # testing UPDATE action view
  def edit
    if request.post?
      update(params[:tag_old_name], params[:tag_new_name], params[:tag_status], params[:tag_type])
      session[:tmsg] = "Updated."
      redirect_to "/of/site_admin/site_admin/manage_tags"
    end
  end

  # testing DESTROY action view by mutiple tag ids
  def delete
    if request.post?
      if params[:tag_id].include?(",")
        params[:tag_id].split(",").each{ |tid| destroy(tid.strip) }
        redirect_to "/of/site_admin/site_admin/manage_tags"
      else
        destroy(params[:tag_id])
        redirect_to "/of/site_admin/site_admin/manage_tags"
      end
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
      redirect_to "/of/site_admin/site_admin/manage_tags"
    end
  end

  def pending
    if request.post?
      params[:tag_id].split(",").each do |tid| 
        @pending_tag = Tagcloud.find_by_id(tid)
        @pending_tag.status = 0 if @pending_tag.status == 1
        @pending_tag.save
      end
      session[:tmsg] = "Pending Ok!"
      redirect_to "/of/site_admin/site_admin/manage_tags"
    end
  end

  def new(tname, tstatus, ttype)
    @tag = Tagcloud.find_by_name(tname)
    @tag_id = @tag.id unless @tag.nil?
    if @tag.nil?
      @new_tag = Tagcloud.new
      @new_tag.name = tname.strip
      @new_tag.tag_type = ttype
      @new_tag.status = tstatus
      @tag_id = @new_tag.id if @new_tag.save
      session[:ided] = "#{@tag_id.to_s}"
      session[:tmsg] = "'#{tname}' added."
    else
      session[:tmsg] = "#{tname} was already exists."
    end
  end

  def update(oldname, newname, newstatus, newtype)
    @tag = Tagcloud.find_by_name( oldname )
    unless @tag.nil?
      begin
        @tag.name = newname
        @tag.status = newstatus
        @tag.tag_type = newtype
        session[:tmsg] = @tag.to_json if @tag.save
        session[:ided] = "#{@tag.id.to_s}"
      rescue
        session[:tmsg] = "Something wrong man~"
      end
    end
  end

  protected
  def destroy(tid)
    t = Tagcloud.find_by_id( tid )
    t.destroy if t
    Project.find_with_ferret("alltags_string:'#{t.name.to_s}'").map{|p| p.save}
  end

end
