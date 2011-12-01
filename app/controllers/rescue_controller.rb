class RescueController < ApplicationController
  def rescue_routing_error
    redirect_to rescue_not_found_path
  end

  def not_found
  end

end
