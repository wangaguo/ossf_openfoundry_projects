# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

#
# URL: http://xxx.xxx.xxx.xxx/rss?cont=[param]&qs=[param]&fmt=[param]
#
# Description:
#
# RSS generator with specified RSS version/format that generating by user
# request.
#
# Currently provide content: new project, project news, project release and
# project activities
#
# Parameters:
#
# [cont]
# new_project: latest new projects
# proj_release: latest project release
# news_publish: latest news publish
#
# [qs]
# Query size, default is 10, 0 will be treat as empty value.
#
# [fmt]
# RSS format. Currently support Atom & RSS 2.0.
#
# Response formats:
#
# <Atom> [200, {"Content-Type" => "application/atom+xml"}, [rss.to_s]]
# <RSS> [200, {"Content-Type" => "application/rss+xml"}, [rss.to_s]]
# <XML> [200, {"Content-Type" => "text/xml"}, [rss.to_s]]
#
# Limitation:
#
# Max query size is 30. To prevent too much query size causes system runs into
# high loading.
#

class Rss
  def self.call(env)
    content_type = 'text/html'
    output = ''

    if env['PATH_INFO'] =~ /^\/of\/rss/
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

        # format initialize, default is atom
        rss_formats = ['atom', 'rss']
        rss_format = rss_formats.member?( params['fmt'])? params['fmt'] :'atom'

        # basic variables initialize
        data_array = []
        of_domain = 'of.openfoundry.org'
        property = {
          'type' => params['cont'],
          'link' => of_domain,
          'language' => 'UTF-8',
          'author' => 'OpenFoundry',
          'project_url' => "http://#{of_domain}/projects/"
        }

        case params['cont']
        when 'new_project'
          property['type'] = params['cont']
          property['title'] = 'OpenFoundry: New Projects Feed'
          property['description'] = 'New projects on OpenFoundry'

          data = Project.find(:all, :select => 'id as project_id, summary as title, description, created_at as updated', :conditions => Project.in_used_projects, :order => 'created_at desc', :limit => query_size)
          data.map { | row |
            data_hash = row.attributes
            data_array.push(data_hash)
          }
        when 'proj_release'
          property['type'] = params['cont']
          property['title'] = 'OpenFoundry: Latest Releases'
          property['description'] = 'Latest releases on OpenFoundry'

          # use customized query instead, format purpose
          data = Release.find_by_sql("SELECT releases.project_id, releases.version, projects.summary as title, projects.description, releases.created_at as updated FROM releases LEFT OUTER JOIN projects ON projects.id = releases.project_id WHERE releases.status = 1 AND projects.status = 2 ORDER BY releases.created_at desc LIMIT #{query_size}")
          data.map { | row |
            data_hash = row.attributes
            data_array.push(data_hash)
          }
        when 'news_publish'
          property['type'] = params['cont']
          property['title'] = 'OpenFoundry: Project News'
          property['description'] = 'Project news on OpenFoundry'

          data = News.find(:all, :select => 'id, catid as project_id, subject as title, description, updated_at as updated', :conditions => ["catid<>0 and status = #{News::STATUS[:Enabled]}"], :order => 'updated_at desc', :limit => query_size)
          data.map { | row |
            data_hash = row.attributes
            data_array.push(data_hash)
          }
        when 'proj_acts'
          query_size = (query_size % 3 == 0) ? query_size / 3 : (query_size / 3).ceil + 1

          property['type'] = params['cont']
          property['title'] = 'OpenFoundry: Project Activities'
          property['description'] = 'Project activities on OpenFoundry'

          data = Project.find(:all, :select => 'id as project_id, summary AS title, name as project_name, created_at as updated', :conditions => Project.in_used_projects, :order => 'created_at desc', :limit => query_size)
          data.map { | row |
            data_hash = row.attributes
            data_hash['type'] = 'new_project'
            data_array.push(data_hash)
          }

          data = Release.find_by_sql("SELECT releases.project_id, releases.version, projects.summary AS title, projects.name AS project_name, releases.created_at AS updated FROM releases LEFT OUTER JOIN projects ON projects.id = releases.project_id WHERE releases.status = 1 AND projects.status = 2 ORDER BY releases.created_at DESC LIMIT #{query_size}")
          data.map { | row |
            data_hash = row.attributes
            data_hash['type'] = 'proj_release'
            data_array.push(data_hash)
          }

          data = News.find_by_sql("SELECT news.id, news.catid AS project_id, projects.summary AS title, projects.name AS project_name, news.updated_at AS updated FROM news LEFT OUTER JOIN projects ON projects.id = news.catid WHERE news.catid <> 0 AND news.status = #{News::STATUS[:Enabled]} ORDER BY news.updated_at DESC LIMIT #{query_size}")
          data.map { | row |
            data_hash = row.attributes
            data_hash['type'] = 'news_publish'
            data_array.push(data_hash)
          }
        else
          [200, {'Content-Type' => 'text/html'}, ['Parameter error!']]
        end

        # choose what format will be used
        case rss_format
        when 'rss'
          rss = build_rss_array(property, data_array)
          content_type = 'application/rss+xml'
        when 'atom'
          rss = build_atom_array(property, data_array)
          content_type = 'application/atom+xml'
        else
          # default is atom
          rss = build_atom_array(property, data_array)
          content_type = 'application/atom+xml'
        end

        output = rss.to_s

        [200, {'Content-Type' => content_type}, [output]]
      else
        # Parameter not available
        output = 'Parameter not available!'

        [200, {'Content-Type' => content_type}, [output]]
      end
    else
      # File not found
      output = 'File not found!'

      [404, {'Content-Type' => content_type}, [output]]
    end
  end

  #
  # Build data in Atom format - (Array)
  #
  def self.build_atom_array(property, data_array)
    require 'rss/maker'

    content = RSS::Maker.make('atom') do | maker |
      maker.channel.link = property['link']
      maker.channel.author = property['author']
      maker.channel.language = property['language']

      maker.channel.title = property['title']
      maker.channel.description = property['description']

      maker.channel.date = Time.now
      maker.channel.id = ''

      # sort items by date, but all items have been sorted by
      # database query
      if property['type'] == 'proj_acts' then maker.items.do_sort = true end

      data_array.map { | row |
        maker.items.new_item do | item |
          item.title = row['title']
          item.link = property['project_url'] + "#{row['project_id']}/"

          case property['type']
          when 'news_publish'
            item.link.concat("news?=#{row['id']}")
          when 'proj_release'
            item.title.concat(" - #{row['version']}")
            item.link.concat("download##{row['version']}")
          when 'proj_acts'
            case row['type']
            when 'news_publish'
              item.link.concat("news?=#{row['id']}")
            when 'proj_release'
              item.title.concat(" - #{row['version']}")
              item.link.concat("download##{row['version']}")
            end
          else
            # do nothing
          end

          item.description = row['description']
          item.updated = DateTime.parse(row['updated']).to_s
        end
      }
    end

    #return content
  end

  #
  # Build data in RSS format (RSS 2.0) - (Array)
  #
  def self.build_rss_array(property, data)
    require 'rss/maker'

    version = '2.0'

    content = RSS::Maker.make(version) do | maker |
      maker.channel.link = property['link']
      maker.channel.title = property['title']
      maker.channel.description = property['description']
      maker.channel.date = Time.now

      # sort items by date, but items have been sorted by
      # database query
      if property['type'] == 'proj_acts' then maker.items.do_sort = true end

      data.map { | row |
        item = maker.items.new_item
        item.title = row['title']
        item.link = property['project_url'] + "#{row['project_id']}/"

        case property['type']
        when 'news_publish'
          item.link.concat("news?=#{row['id']}")
        when 'proj_release'
          item.title.concat(" - #{row['version']}")
          item.link.concat("download##{row['version']}")
        when 'proj_acts'
          case row['type']
          when 'news_publish'
            item.link.concat("news?=#{row['id']}")
          when 'proj_release'
            item.title.concat(" - #{row['version']}")
            item.link.concat("download##{row['version']}")
          end
        else
          # do nothing
        end

        item.description = row['description']
        item.date = Time.parse(row['updated'])
      }
    end

    return content
  end

  #
  # Build data in Atom format
  #
  def self.build_atom(property, data)
    require 'rss/maker'

    content = RSS::Maker.make('atom') do | maker |
      maker.channel.link = property['link']
      maker.channel.author = property['author']
      maker.channel.language = property['language']

      maker.channel.title = property['title']
      maker.channel.description = property['description']

      maker.channel.date = Time.now
      maker.channel.id = ''

      # sort items by date, but all items have been sorted by
      # database query
      #maker.items.do_sort = true

      data.map { | row |
        maker.items.new_item do | item |
          item.title = row.title
          item.link = property['project_url'] + "#{row.project_id}/"

          case property['type']
          when 'news_publish'
            item.link.concat("news?=#{row.id}")
          when 'proj_release'
            item.title.concat(" - #{row.version}")
            item.link.concat("download##{row.version}")
          else
            # do nothing
          end

          item.description = row.description
          item.updated = DateTime.parse(row.updated).to_s
        end
      }
    end

    return content
  end

  #
  # Build data in RSS format (RSS 2.0)
  #
  def self.build_rss(property, data)
    require 'rss/maker'

    version = '2.0'

    content = RSS::Maker.make(version) do | maker |
      maker.channel.link = property['link']
      maker.channel.title = property['title']
      maker.channel.description = property['description']
      maker.channel.date = Time.now

      # sort items by date, but items have been sorted by
      # database query
      #maker.items.do_sort = true

      data.map { | row |
        item = maker.items.new_item
        item.title = row.title
        item.link = property['project_url'] + "#{row.project_id}/"

        case property['type']
        when 'news_publish'
          item.link.concat("news?=#{row.id}")
        when 'proj_release'
          item.title.concat(" - #{row.version}")
          item.link.concat("download##{row.version}")
        else
          # do nothing
        end

        item.description = row.description
        item.date = Time.parse(row.updated)
      }
    end

    return content
  end

  #
  # Text translation with GetText
  #
  def self.get_text(text)
    require 'gettext'

    bindtextdomain('openfoundry')

    return _(text)
  end
end
