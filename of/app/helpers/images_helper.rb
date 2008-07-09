module ImagesHelper
  def project_logo_link(project, options={})
  "<a href=/projects/#{project.id}>
     <img src=\"#{url_for(:controller => :images, :action => "image", 
                         :id => project.icon, :size => options[:size]||32)}\" 
         title=\"#{project.name}\" align=#{options[:align]||:middle} />
    </a>"
  end
end
