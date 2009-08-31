require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  fixtures :projects, :users
  
  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @test_session = {'user' => User.find(1)}
    @request.host = "localhost"
    @first_id = @openfoundry.id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:projects)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:project)
    assert assigns(:project).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:project)
  end

  def test_create   
    num_projects = Project.count
  
    post :create,{ :project => {:name => "newproject"+rand(100).to_s} }, @test_session

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_projects + 1, Project.count
  end

  def test_edit
    get :edit, :id => @first_id 

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:project)
    assert assigns(:project).valid?
  end

  def test_update
    post :update, :id => @first_id, :project => {:name => "meow"}
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Project.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Project.find(@first_id)
    }
  end
end
