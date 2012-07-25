class WebhostingController < ApplicationController
  def index
    @module_name = _('menu_WebHosting')
  end

  def how_to_upload
    @module_name = _('How to Upload?')
  end
end
