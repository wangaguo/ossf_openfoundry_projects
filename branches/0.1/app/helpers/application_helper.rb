# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Localization

  #for streamlined...
  def advanced_filtering
    true
  end 
  def breadcrumb
    true
  end 
end
