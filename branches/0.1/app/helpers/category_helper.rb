module CategoryHelper
  def streamlined_side_menus
    [ ["List All Category", {:controller => "category", :action => "list"}] ]
  end
  
  def streamlined_top_menus
    [ ["Add Category", {:controller => "category", :action => "new"}] ]
  end
  
  def streamlined_branding
    link_to "home", "/"
  end

  def streamlined_footer
    "Brought to you by #{ link_to "Caffeine", "http://en.wikipedia.org/wiki/Caffeine" }"
  end	
end
