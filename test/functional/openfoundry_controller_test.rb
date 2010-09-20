require File.dirname(__FILE__) + '/../test_helper'
require 'openfoundry_controller'

# Re-raise errors caught by the controller.
class OpenfoundryController; def rescue_action(e) raise e end; end

class OpenfoundryControllerTest < Test::Unit::TestCase
  def setup
    @controller = OpenfoundryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
