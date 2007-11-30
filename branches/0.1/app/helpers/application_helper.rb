# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Localization 
  #TODO want to build a object view layout 
  def arranged(tag_name, record, options)
    raise ArgumentError.new("should not be #{record.class}") unless ( record.is_a? ActiveRecord::Base )
    
    #TODO more flexible...
    default_options={
      :label_alignment => true,#not implemented
      :fields_per_column => 2,
      :masked_fields => [/^[a-z_]*id$/,/^updated_at$/,/^created_at$/,/^creator$/],
      :extra => false,#not implemented
      :left2right => true,#not implemented
      :editable => false,
      :field_selector => :default_selector
      #...
    }
    options = default_options.merge options
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
    rows = (fields.length.to_f / cols).ceil
    
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
          html << '<td></td>\n<td></td>\n'
        else
          obj = fields[j+i*cols]
          if options[:editable]
            f = options[:editable]
            #必填欄位前面有星星
            star = obj.null ? '':'<strong>*</strong>'
            html << "<td>#{star}#{obj.human_name} : </td>\n"
            #有預設值放預設值
            value = record.send(obj.name)
            value ||= obj.default
            #id用hash產生一組亂數
            id = obj.name
            id = id+id.hash.to_s
            #其他有的沒的
            extra = obj.type == :date ? calendar_for(id) : ''
            html << "<td>"
            html << "<input id=#{id} name=#{obj.name} value=\"#{value}\"/>#{extra}"
            html << "</td>\n"
          else
            html << "<td> #{obj.human_name} : </td>\n"
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
end

   