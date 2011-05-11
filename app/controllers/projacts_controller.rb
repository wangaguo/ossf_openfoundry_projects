#
# URL: http://xxx.xxx.xxx.xxx/of/proj_acts?qs=[param]
#
# Description:
#
# Render only project activities with customized HTML format.
#
# Parameters:
#
# [qs]
# Query size, default is 10, 0 will be treat as empty value.
#
# Limitation:
#
# Max query size is 30. To prevent too much query size causes system runs into
# high loading.
#
# Response formats:
#
# self.response_body output
#
# Output content has been customized for design requirement
#

class ProjactsController < ActionController::Metal
   def index
    output = ''

    if req = Rack::Request.new(env) and req.get?
      params = req.params

      # size initialize
      max_size = 30
      query_size = 10

      if params.key?('qs')
        query_size = (params['qs'].empty? or params['qs'].to_i == 0) ? 10 : params['qs'].to_i
      end

      # size limitation checking
      if query_size.to_i > max_size
        query_size = max_size
      end

      # Set each item's query size
      query_size = (query_size % 3 == 0) ? query_size / 3 : (query_size / 3).ceil + 1

      # other needed variables
      data_array = []
      of_domain = OPENFOUNDRY_HOST
      project_url = "#{OPENFOUNDRY_OF_URL}/projects/"
      h_stat = {
        'new_project'  => {
          'text' => '<span class="pa_new">New</span>',
          'desc' => 'project just created'
        },
        'news_publish' => {
          'text' => '<span class="pa_publish">Publish</span>',
          'desc' => 'a project news'
        },
        'proj_release' => {
          'text' => '<span class="pa_release">Release</span>',
          'desc' => 'a new file'
        }
      }

      # Get "New project"
      data = Project.find(:all, :select => 'id as project_id, name as project_name, created_at as updated', :conditions => Project.in_used_projects, :order => 'created_at desc', :limit => query_size)
      data.map { | row |
        data_hash = row.attributes
        data_hash['type'] = 'new_project'
        data_hash['updated'] = Time.parse(data_hash['updated']) # for sorting purpose
        data_array.push(data_hash)
      }

      # Get "Latest release"
      data = Release.find_by_sql("SELECT releases.project_id, releases.version, projects.name AS project_name, releases.created_at AS updated FROM releases LEFT OUTER JOIN projects ON projects.id = releases.project_id WHERE releases.status = 1 AND projects.status = 2 ORDER BY releases.created_at DESC LIMIT #{query_size}")
      data.map { | row |
        data_hash = row.attributes
        data_hash['type'] = 'proj_release'
        data_hash['updated'] = Time.parse(data_hash['updated']) # for sorting purpose
        data_array.push(data_hash)
      }

      # Get "Latest news"
      data = News.find_by_sql("SELECT news.id, news.catid AS project_id, projects.name AS project_name, news.updated_at AS updated FROM news LEFT OUTER JOIN projects ON projects.id = news.catid WHERE news.catid <> 0 AND news.status = #{News::STATUS[:Enabled]} ORDER BY news.updated_at DESC LIMIT #{query_size}")
      data.map { | row |
        data_hash = row.attributes
        data_hash['type'] = 'news_publish'
        data_hash['updated'] = Time.parse(data_hash['updated']) # for sorting purpose
        data_array.push(data_hash)
      }

      # sorting in array
      data_array = (data_array.sort_by { | row | row['updated'] }).reverse

      # Construct output
      output = '<div id="pa"><ul>'

      data_array.map { | row |
        url = project_url + "#{row['project_id']}/"

        case row['type']
        when 'proj_release'
          url.concat("download##{row['version']}")
        when 'news_publish'
          url.concat("news?=#{row['id']}")
        else
          # do nothing
        end

        output.concat("<li><a href=\"#{url}\">#{row['project_name']}</a> #{h_stat[row['type']]['text']} #{h_stat[row['type']]['desc']}. <span class=\"published-date\">#{row['updated'].gmtime.in_time_zone.strftime('%Y-%m-%d')}</span></li>\n")
      }

      output.concat('</ul></div>')

      # render
      self.response_body = output
    else
      # Parameter not available
      output = 'Parameter not available!'

      self.response_body = output
    end
  end
end
