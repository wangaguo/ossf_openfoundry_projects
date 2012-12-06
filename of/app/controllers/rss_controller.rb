#
# Parameters:
#
# --> options
# new_project
# new_release
# top_download
# project_news
# site_news
#
# --> query_size
# number of items
#

class RssController < ApplicationController 
  def index 
    query_size = 10

    @rssdata = []
    @property = {}

    case params['cont']
    when 'new_project'
      @property[:title] = 'OpenFoundry: New Projects Feed'
      @property[:description] = 'New projects on OpenFoundry'

      data = Project.in_used.find(:all, :select => 'id, summary, description, created_at', :order => 'created_at DESC', :limit => query_size)

      data.each { |row|
        t_rss = Feed.new
        t_rss.title = "#{row.summary}" 
        t_rss.description = "#{row.description}" 
        t_rss.date = row.created_at 
        t_rss.link = project_url(:id => row.id)
        @rssdata.push(t_rss)
      }
    when 'new_release'
      @property[:title] = 'OpenFoundry: Latest Releases'
      @property[:description] = 'Latest releases on OpenFoundry'

      data = Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "releases.created_at DESC", :limit => query_size)

      data.each { |row|
        t_rss = Feed.new
        t_rss.title = "#{row.project.summary} #{row.version}"
        t_rss.description = "#{row.project.description}"
        t_rss.date = row.created_at
        t_rss.link = project_url(:id => row.project_id)
        @rssdata.push(t_rss)
      }
    when 'top_download'
      @property[:title] = 'OpenFoundry: Top Download'
      @property[:description] = 'Top download on OpenFoundry'
      
      data = Release.top_download.limit(query_size)

      data.each { |row|
        r_page = Release.find(:all, :conditions => "project_id = #{row.project_id} AND status = 1", :order => "due DESC").map {|e| e.version}.index("#{row.version}") / 5 + 1

        t_rss = Feed.new
        t_rss.title = "#{row.project.summary} #{row.version}"
        t_rss.description = "#{row.project.description}"
        t_rss.date = row.created_at
        t_rss.link = project_download_url(:project_id => row.project_id, :page => r_page) + "##{row.version}"
        @rssdata.push(t_rss)
      }
    when 'project_news'
      @property[:title] = 'OpenFoundry: Project News'
      @property[:description] = 'Project news on OpenFoundry'

      data = News.find(:all, :conditions => ["catid<>0 and status = #{News::STATUS[:Enabled]}"], :order => "updated_at DESC", :limit => query_size)

      data.each { |row|
        t_rss = Feed.new
        t_rss.title = "#{row.subject}"
        t_rss.description = "#{row.description}"
        t_rss.date = row.updated_at 
        t_rss.link = project_news_url(:project_id => row.catid, :id => row.id)
        @rssdata.push(t_rss)
      }
    when 'site_news'
      @property[:title] = 'OpenFoundry: System News'
      @property[:description] = 'System news on OpenFoundry'

      data = News.find(:all, :conditions => ["catid=0 and status = #{News::STATUS[:Enabled]}"], :order => "updated_at DESC", :limit => query_size)

      data.each { |row|
        t_rss = Feed.new
        t_rss.title = "#{row.subject}"
        t_rss.description = "#{row.description}" 
        t_rss.date = row.updated_at
        t_rss.link = news_url(:id => row.id) 
        @rssdata.push(t_rss)
      }
    end

    unless @rssdata.empty?
      respond_to do |format|
        format.rss
        format.atom
      end
    end
  end
end
