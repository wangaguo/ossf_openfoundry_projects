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
      rtn += " <img src=\"/images/cc/#{x}_standard.gif\" width=\"16\">"
    end
    rtn
  end
  def project_logo_link(project, options={:with_name => false})
    "<span class=\"project_logo\"><a href=\"/projects/#{project.id}\">
     #{options[:with_name] ? project.name : '' }
     <img src=\"#{url_for(:controller => :images, :action => "cached_image", 
                         :id => "#{project.icon}_#{options[:size]||32}")}\" 
         title=\"#{project.name}\" align=#{options[:align]||:middle} />
    </a></span>"
  end
end
