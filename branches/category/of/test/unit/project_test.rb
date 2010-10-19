require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :users

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def apply_a_new_project
    Project.apply({:name => 'testproject1'}, User.find(1))
  end
  def find_the_new_project
    Project.find_by_name('testproject1')
  end

  def test_apply
    apply_a_new_project
    p = find_the_new_project
    assert_equal 'testproject1', p.name
    assert_equal Project::STATUS[:APPLYING], p.status
  end

  def test_approve
    p = apply_a_new_project
    p.approve("test approve")

    p = find_the_new_project
    assert_equal Project::STATUS[:READY], p.status
    assert_equal "test approve", p.statusreason
  end
  def test_approve_wrong_status
    p = Project.find(2) # fixture 2 is 'READY'
    assert_equal Project::STATUS[:READY], p.status
    assert_raise RuntimeError do
      p.approve("test approve")
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
    p = Project.find(2) # fixture 2 is 'READY'
    assert_equal Project::STATUS[:READY], p.status
    assert_raise RuntimeError do
      p.reject('test reject')
    end
  end

  def test_suspend
    p = Project.find(2) # fixture 2 is 'READY'
    assert_equal Project::STATUS[:READY], p.status
    p.suspend('test suspend')

    p = Project.find(2)
    assert_equal Project::STATUS[:SUSPENDED], p.status
    assert_equal 'test suspend', p.statusreason
  end
  def test_reject_wrong_status
    p = Project.find(1) # fixture 1 is 'APPLYING'
    assert_equal Project::STATUS[:APPLYING], p.status
    assert_raise RuntimeError do
      p.suspend('test suspend')
    end
  end

  def test_resume
    p = Project.find(2) # fixture 2 is 'READY'
    assert_equal Project::STATUS[:READY], p.status
    p.suspend('test suspend')
    p.resume('test resume');

    p = Project.find(2)
    assert_equal Project::STATUS[:READY], p.status
    assert_equal 'test resume', p.statusreason
  end
  def test_resume_wrong_status
    p = Project.find(1) # fixture 1 is 'APPLYING'
    assert_equal Project::STATUS[:APPLYING], p.status
    assert_raise RuntimeError do
      p.resume('test suspend')
    end
  end
end
