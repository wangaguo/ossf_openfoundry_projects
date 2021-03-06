module ProjectsHelper
  def cc_images(license) # int
    rtn = ""
    case license
    when 2: ["by", "nc", "nd"]
    when 3: ["by", "nc", "sa"]
    when 4: ["by", "nc"      ]
    when 5: ["by",       "nd"]
    when 6: ["by",       "sa"]
    when 7: ["by"            ]
    else []
    end.each do |x|
      rtn += " <img src=\"#{root_path}/images/cc/#{x}_standard.gif\" width=\"16\"/>"
    end
    rtn
  end

  def project_logo_link(project, options={:with_name => false, :float => nil})
    "<div class=\"project_logo\" title=\"#{project.name}\"
    style=\"#{options[:float] ? "float:#{options[:float]};" : 'display:inline;'}
    height:#{options[:with_name] ? '55' : '32' }px;
    width:#{options[:with_name] ? '80' : '32' }px;
    border:dotted 1px #eee; text-align:center; vertical-align:text-bottom;
    white-space:normal; word-break:break-all; overflow:hidden; margin-bottom:3px; line-height: normal;\">
    <a href=\"#{options[:action] ? eval(options[:action]+"_project_path(project)") : project_path(project)}#self\" #{options[:rdf_tag]}>
    <img src=\"#{cached_image_images_path(:id => "#{project.icon}_#{options[:size]||32}")}\"
             title=\"#{project.name}\" align=\"#{options[:align]||:middle}\" />
     #{options[:with_name] ? "<br/> #{project.name}" : '' }
    </a></div>".html_safe
  end

  # This method will generate tr>td tags if value is present
  def row_for(title, &value_block)
    # http://asciicasts.com/episodes/208-erb-blocks-in-rails-3
    value = with_output_buffer(&value_block).strip
    if strip_tags(value).present?
      content_tag(:tr) do
        content_tag(:td, "#{title}：", :class => 'fieldstyle') +
          content_tag(:td, value)
      end
    end
  end

  def show_with_seperator(v) 
    raw v.split(/,/).
      map(&:strip).     # remove spaces around string
      reject(&:blank?). # remove blank element like '', nil, ...
      map { |elem| content_tag(:span, elem) }.
      join(', ')
  end
end
