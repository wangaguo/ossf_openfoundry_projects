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
  def breadcrumbs(options={})
    #TODO table or list?
    html = "<table class=\"#{options[:class]}\"> \n<tr>\n"
    
    url = request.path.split('?')  #remove extra query string parameters
    levels = url[0].split('/') #break up url into different levels
    #if not 'home' page, give a 'home' link
    html << addcrumb( _('Home') , '/') unless levels.empty? 
    level_class=nil
    level_title='name'
    levels.each_with_index do |level, index|
      unless level.blank?
        if level =~ /[a-z]+/
          case level
          when 'user'
            level_name, level_class, level_title = 
              _('user'), User, 'login'
          when 'projects'
            level_name, level_class, level_title = 
              _('Projects List'), Project, 'name'
          when 'releases'
            level_name, level_class, level_title = 
              _('Project Releases'), Release, 'name'
          when 'news'
            level_name, level_class, level_title = 
              _('Project News'), News, 'subject'
          when 'rt'
            level_name, level_class, level_title = 
              _('Issue Tracker'), "rt", 'subject'
          end
        elsif level =~ /\d/
          if(["rt"].include?(level_class)==false)
            level_name = level_class.find(level).send(level_title)
          end
        end
        if index == levels.size-1 #|| 
            #(level == levels[levels.size-2] && levels[levels.size-1].to_i > 0)
          #html << "<td>#{level.gsub(/_/, ' ')}</td>\n" unless level.to_i > 0
          html << addcrumb(level_name) unless (level.to_i > 0 or level_name.nil?) 
        else
          link='/'+levels[1..index].join('/')
          html << addcrumb(level_name,link)
        end
      end
    end
    html << "</tr>\n</table>\n"
  end
  
  def addcrumb(name,path = nil)
    name = "<a href=\"#{path}\">#{name}</a>" unless path.nil?
    "<td>&raquo;#{name}</td>\n"
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
            html << "<td> #{record.send(obj.name)} </td>\n"
          end
        end
      end
      
      html << "</tr>\n"
    end
    
    html<<"</table> <!-- \"#{tag_name}\"-->"
  end
  
  def calendar_for(field_id)
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
      javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end
  
  def show_flash
    keys  = [:error, :warning, :notice, :message]
    keys.collect { |key| content_tag(:p, flash[key],
                                     :class => "flash#{key}") if flash[key] 
                 }.join
  end

  def language_select(name, selected, options = {})
    language_options = options_for_select([["English", "en"],["繁體中文", "zh_TW"]], selected)
    select_tag name, language_options, options
  end
  
  def fpermit?(project_name, function_name)
    Function.function_permit(project_name, function_name)
  end
  
  def help_icon(tooltip)
    '<a class="help"><img src="/images/icon/help.png"/><span>' + tooltip + '</span></a>'
  end
  
  class TwoColumnFormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::TagHelper
    def label(method, text = nil, options = {})
      help = options[:help]
      must = @object.class.columns_hash[method.to_s]
      must = (must and not must.null)||options[:must] ? '<em class="required">*</em>' : nil
      
      "<tr><th>#{super(method, text, options )} #{must} #{help_icon(help) if help}</th>"
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      "<td>#{super(method, options, checked_value, unchecked_value)}</td></tr>"
    end
    
    def text_field(method, options = {})
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
      "<td>#{content_tag :select, option_tags, { "name" => name, "id" => name }.update(options.stringify_keys)}</td></tr>"
    end
  end
end

   
