module ImagesHelper
  def project_logo_link(project, options={})
    content_tag(:a, 
                tag(:img,
                    :src => cached_image_images_path(project),
                    :size => options[:size] || 32,
                    :title => project.name,
                    :align => options[:align] || :middle),
                :href => projects_path(project))
    #"<a href=/projects/#{project.id}>
    #   <img src=\"#{url_for(:controller => :images, :action => "cached_image", 
    #                       :id => project.icon, :size => options[:size]||32)}\" 
    #       title=\"#{project.name}\" align=#{options[:align]||:middle} />
    #  </a>"
  end
end
