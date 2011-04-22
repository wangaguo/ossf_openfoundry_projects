# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def viewports_manager(options={})
    #TODO add extension here
    default_options={
      :viewports => {:list => '完整列表', :icon => '圖示'}
    }
    options = default_options.merge(options)
    html ="<select onchange=\"#{remote_function(:update => options[:update],
         :url => options[:url]                     
        )}\">\n"
    options[:viewports].each do |option,name|
      html << "<option value=\"#{option}\">#{name}</option>\n"
    end
    html << "</select>\n"
  end
  
  def table_viewport(items,options={})
    raise ArgumentError unless (items.is_a? Array and options.is_a? Hash)
    
    #TODO add extension here
    default_options={
      :tag => {'id' => 'viewport', 'class' => 'viewport_table'},
      :sort => {:index => :id, :order => :dec}
    }
    options = default_options.merge(options)
    tag=options[:tag].collect{|i| "#{i[0]}=\'#{i[1]}\'"}
    html = "<div class><table class= id>"
    html = "</table></div>"
    html = "<table #{tag}>\n"
    
    
    
    html << "</table>\n"
  end
  
  #TODO to be optimized! about this breadcrumb, see http://joshhuckabee.com/node/58
  def breadcrumbs(module_name=nil)
    html = "<a id='breadcrumbs-home' href='/'></a><span class=\"breadcrumbs pathway\"> \n"
    hierarchy = 1 

    url = request.path.gsub(ROOT_PATH, '').split('?')  #remove extra query string parameters # url remove ROOT_PATH for Rails 3
    levels = (url[0] || '' ).split('/') #break up url into different levels
    if levels[1] == 'download_path'
      levels = [ '', 'projects', Project.find_by_name(levels[2]).id.to_s, 'download', levels[4] ]
    end
    level_name=""
    level_class=nil
    level_title='name'
    levels.each_with_index do |level, index|
      unless level.blank?
        hierarchy += 1
        if level =~ /[a-z]+/
          case level  
          when 'releases'
            level_name, level_class, level_title = 
              _('Project Releases'), Release, 'version'
          when 'user'
            level_name, level_class, level_title = 
              _('user'), User, 'login'
          when 'projects'
            level_name, level_class, level_title = 
              _('Project Listing'), Project, 'name'
          when 'category'
            level_name, level_class, level_title = 
              _('Project Listing'), Project, 'name'
          when 'news'
            level_name, level_class, level_title = 
              _('News'), News, 'subject'
          when 'jobs'
            level_name, level_class, level_title = 
              _('Help Wanted'), Job, 'subject'
          when 'citations'
            level_name, level_class, level_title = 
              _('Citations'), Citation, 'project_title'
          when 'references'
            level_name, level_class, level_title = 
              _('References'), Reference, 'source'
          when 'rt'
            level_name, level_class, level_title = 
              _('Issue Tracker'), "rt", 'subject'
          when 'download_path', 'download'
            level_name, level_class, level_title = 
              _('Downloads'), nil, nil
          when 'top'
            level_name, level_class, level_title = 
              _('Top Downloads'), nil, nil
          when 'latest'
            level_name, level_class, level_title = 
              _('Latest Releases'), nil, nil
          when 'help'
            level_name, level_class, level_title = 
              _('Help'), 'help', nil
          when 'survey'
            level_name, level_class, level_title = 
              _('Survey'), 'survey', nil
          when 'webhosting'
            level_name, level_class, level_title = 
              _('menu_WebHosting'), 'webhosting', nil
          else
            if (["help"].include?(level_class)==true) 
              level_name = ''
            else
                logger.error "!!!!!"+level+"!!!"+ROOT_PATH
              if hierarchy == 2 and "/#{level}" == ROOT_PATH
                level = "of" 
                logger.error "!!!!!"+level+"!!!"+ROOT_PATH
              end
              if ( _( "breadcrumb|" + level ) == "breadcrumb|" + level )
                logger.error "!!!!!"+url_unescape(level).humanize.capitalize
                level_name = h( url_unescape(level).humanize.capitalize )
              else
                begin
                  level_name_char = h(level)
                  level_name = left_slice(level_name_char, 20)
                  if level_name_char.length > level_name.length
                    level_name += "..."
                  else
                    level_name = _( "breadcrumb|" + level )
                  end
                rescue
                  level_name = _( "breadcrumb|" + level )
                end
              end
            end
          end
        elsif level =~ /\d/# and level_class
          if(["rt","help","survey"].include?(level_class)==false)
            begin
              level_name_char = h(level_class.find(level).send(level_title).mb_chars)
              level_name = left_slice(level_name_char, 20)
              if level_name_char.length > level_name.length
                level_name += "..."
              end
            rescue
              level_name = h(level)
            end
          end
        end
        if index == levels.size-1 
          if (level_name.length > 20 or level_class == User)# or (level_name.length > 20 and level_class == User) 
            html << addcrumb(level_name, hierarchy) unless (level_name.nil?)
          else
            unless (@module_name.nil?) then html << addcrumb(@module_name, hierarchy) else html << addcrumb(level_name, hierarchy) end
          end
        else
          link = "/"+levels[1..index].join('/')
          html << addcrumb(level_name, hierarchy, link)
        end
      end
    end
    if levels.empty?
        html << '<span class="no-link">' + _("Projects") + "</span>"
    end
    html << "\n</span>\n"
  end
  
  def addcrumb(name,level,path = nil)
    if path
      name = "<a class='pathway' href=\"#{root_path}#{path}\">#{name}</a>" unless path.nil?
    else
      name = "<span class='no-link'>#{name}</span>"
    end
  end

  def arranged_select(tag_name, records, options = {})
    raise ArgumentError.new("should not be #{record.class}") unless ( records.is_a? Array )
    html = "<select class=#{tag_name}>"
    #select_options = {:fields_per_column => -1, :with_label => false}
    records.each_with_index do |record, i|
      html << "<option class=#{options[:option_tag]} "
      html << "selected" if i == options[:selected]
      html << ">#{record.name}</option>"
    end
    html << "</select>"  
    html
  end
  
  def arranged_list(tag_name, records, options = {})
    raise ArgumentError.new("should not be #{record.class}") unless ( records.is_a? Array )
    html = "<table class=#{tag_name}>"
    list_options = {:fields_per_column => -1, :with_label => false}
    records.each_with_index do |record, i|
      html << arranged("#{tag_name}_#{i}", record, options.merge(list_options) )
    end
    html << "</table>"  
    html
  end
  
  #TODO want to build a object view layout 
  def arranged(tag_name, record, options = {})
    raise ArgumentError.new("should not be #{record.class}") unless ( record.is_a? ActiveRecord::Base )
    
    #TODO more flexible...
    default_options={
      :style => :table,
      :with_label => true,
      :label_alignment => true,#not implemented
      :fields_per_column => 1,
      :masked_fields => [/^[a-z_]*id$/,/^updated_at$/,/^created_at$/,/^creator$/,
                          /_counter$/,/^icon$/],
      :extra => false,#not implemented
      :left2right => true,#not implemented
      :editable => false,
      :field_selector => :default_selector
      #...
    }
    options.reverse_merge! default_options
    html="<table class=#{tag_name} >" #like <div class=xxx id=xxx>
    
    #把不要show的欄位拿掉
    fields = record.class.content_columns
    options[:masked_fields].each do |mask|
      fields.reject! {|c| c.name =~ mask }
    end
    
    #how many cols? rows?
    #like this: r=3,c=2 =>
    # X X 
    # X X
    # X X
    cols = options[:fields_per_column] 
    if cols > 0 
    rows = (fields.length.to_f / cols).ceil 
    else
    (rows = 1;cols = fields.length) 
    end
    rows.times do |i| 
      html << "<tr>"
      
      #left2right:              up2down:
      #1 2 3                    1 4 7
      #4 5 6                    2 5 8
      #7 8 9                    3 6 9
      #if options[:left2right]
      #end
      cols.times do |j|
        if j+i*cols >= fields.length 
          #空的cell
          html << "<td></td>\n"
          html << "<td></td>\n" if options[:with_label]
        else
          obj = fields[j+i*cols]
          if options[:editable]
            f = options[:editable]
            #必填欄位前面有星星
            if options[:with_label]
              star = obj.null ? '':"<em class='require'>*</em>"
              html << "<th>#{star}#{obj.human_name} : </th>\n"
            end
            #有預設值放預設值
            value = record.send(obj.name)
            value ||= obj.default
            #其他有的沒的
            extra = obj.type == :date ? 
            calendar_for(f.object_name.to_s+'_'+obj.name) : ''
            html << "<td>"
            #html << "<input id=#{id} name=#{obj.name} value=\"#{value}\"/>#{extra}"
            html << f.text_field(obj.name, :size => 20)
            html << extra
            html << "</td>\n"
          else
            html << "<th> #{obj.human_name} : </th>\n" if options[:with_label]
            value = record.send(obj.name)
            if options[:display_filter] and options[:display_filter][obj.name.to_sym]
              value = send(options[:display_filter][obj.name.to_sym], value)
            end
            html << "<td> #{value} </td>\n"
          end
        end
      end
      
      html << "</tr>\n"
    end
    
    html<<"</table> <!-- \"#{tag_name}\"-->"
  end
  
  def calendar_for(field_id)
    image_tag("calendar.gif", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
      javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end
  
  def show_flash
    keys  = [:error, :warning, :notice, :message]
    keys.collect { |key|
      if flash[key] 
        # 原先的版本只吃字串訊息,
        # 修正後的版本可以處理塞在 flash 中的陣列 (any_model.errors.full_message), 輸出成 ul>li*n 的樣式.
        if flash[key].is_a? Array
          content_tag(:div, 
                      content_tag(:ul, flash[key].map { |msg| content_tag(:li, msg) }.join), 
                      :class => "flash#{key}") 
        else
          content_tag(:div, flash[key].to_s, :class => "flash#{key}") 
        end
      end
    }.join
  end

  def language_select(name, selected, options = {})
    language_options = options_for_select([["English", "en"],["繁體中文", "zh_TW"]], selected)
    select_tag name, language_options, options
  end
  
  def help_icon(tooltip)
    '<img src="' + root_path + '/images/icon/help.gif" alt="' + tooltip + '" title="' + tooltip + '"/>'
  end
  
  def required_icon
    t = _("required_icon")
    content_tag(:em, image_tag('icon/star.gif', :alt => t, :title => t), :class => 'required')
  end

  def tz_date(time_at)
    begin
      time = Time.zone.utc_to_local(time_at.utc)
      time.strftime("%Y-%m-%d")
    rescue
      ""
    end
  end
  
  def tz_datetime(time_at)
    begin
      time = Time.zone.utc_to_local(time_at.utc)
      time.strftime("%Y-%m-%d %H:%M") + ' ' + Time.zone.formatted_offset
    rescue
      ""
    end
  end
  
  def users_for_select(users, options={})
    users.collect!{ |user| "<option value=\"#{user.id}\">
      #{user.login}
      </option>" }.join('\n')
  end
 
  def url_escape(string)
    string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '+')
  end

  def url_unescape(string)
    string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
      [$1.delete('%')].pack('H*')
    end
  end

  class TwoColumnFormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::TagHelper

    def required_icon
      t = _("required_icon")
      content_tag(:em, image_tag('icon/star.gif', :alt => t, :title => t), :class => 'required')
    end
    def help_icon(tooltip)
      '<img src="' + root_path + '/images/icon/help.gif" alt="' + tooltip + '" title="' + tooltip + '"/>'
    end
    
    def label(method, text = nil, options = {})
      help = options.delete :help
      must = @object.class.columns_hash[method.to_s]
      must = (must and not must.null)||options[:must] ?  required_icon : nil
      
      "<tr><th>#{super(method, text, options )} #{must} #{help_icon(help) if help}</th>"
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      "<td>#{super(method, options, checked_value, unchecked_value)}</td></tr>"
    end
    
    def text_field(method, options = {})
      "<td>#{super(method, options )}</td></tr>"
    end

    def text_area(method, options = {})
      "<td>#{super(method, options )}</td></tr>"
    end
    
    def password_field(method, options = {})
      "<td>#{super(method, options )}</td></tr>"
    end
    
    def language_select(name, selected, options = {})
      language_options = options_for_select([["English", "en"],["繁體中文", "zh_TW"]], selected)
      select_tag( name, language_options, options)
    end
    
    def select_tag(name, option_tags = nil, options = {})
      "<td>#{content_tag :select, option_tags, { "name" => name, "id" => name }.update(options)}</td></tr>"
    end

    def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
      "<td>#{super(@object_name, method, priority_zones, options.merge(:object => @object), html_options)}</td></tr>"
    end
  end

  def nl2br(htmlstring)
    htmlstring.gsub("\n\r", "<br />").gsub("\r", "").gsub("\n", "<br />")
  end

  def ts(st)
    st.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  def hash_try_chain(hash, *keys)
    keys.inject(hash) { |h, k| h.try(:[], k) }
  end

  alias :htc :hash_try_chain

end

   
