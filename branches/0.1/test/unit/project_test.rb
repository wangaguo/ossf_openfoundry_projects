require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :users

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def apply_a_new_project
    Project.apply({:unixname => 'testproject1'}, User.find(1))
  end
  def find_the_new_project
    Project.find_by_unixname('testproject1')
  end

  def test_apply
    apply_a_new_project
    p = find_the_new_project
    assert_equal 'testproject1', p.unixname
    assert_equal Project::STATUS[:APPLYING], p.status
  end

  def test_approve
    p = apply_a_new_project
    p.approve

    p = find_the_new_project
    assert_equal Project::STATUS[:READY], p.status
  end
  def test_approve_wrong_status
    p = Project.find(1) # fixture 1 is 'READY'
    assert_raise RuntimeError do
      p.approve
    end
  end

  def test_reject
    p = apply_a_new_project
    p.reject('test reject')

    p = find_the_new_project
    assert_equal Project::STATUS[:REJECTED], p.status
    assert_equal 'test reject', p.statusreason
  end
  def test_reject_wrong_status
    p = Project.find(1) # fixture 1 is 'READY'
    assert_raise RuntimeError do
      p.reject('test reject')
    end
  end

end
