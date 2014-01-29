module ReleasesHelper
  def show_release(release)
    html=''
    html << '<fieldset><dl>'
    for column in Release.content_columns 
      html << "<dt>#{column.human_name}:</dt><dd>#{release.send(column.name)}</dd>"
    end
    html << '</dl>'
    release.fileentity.each do |f|
      for column in Fileentity.content_columns
        html << "<dt>#{column.human_name}:</dt><dd>#{f.send(column.name)}</dd>"
      end
      html << '</dl>'
    end
    html << '</fieldset>'
    html
  end

  def toggle_lock_text(release)
    release.lock? ? _('nsc.unlock') : _('nsc.lock')
  end
end
