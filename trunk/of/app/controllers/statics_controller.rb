class StaticsController < ApplicationController
  def update
    @data = params[:data].split('※')
    @row = DownloadStatic.where(:project=>@data[0]).where(:version=>@data[1]).where(:file=>@data[2]).where(:date=>@data[3]).first
    if @row.blank?
      @log = {}
      @log["project"] = @data[0]
      @log["version"] = @data[1]
      @log["file"] = @data[2]
      @log["date"] = @data[3]
      @log["count"] = @data[4]
      a = DownloadStatic.new(@log)
      a.save
    else
      @row.update_attribute(:count,@data[4])
      @row.save
    end


    render :text => params[:data]
  end

end
