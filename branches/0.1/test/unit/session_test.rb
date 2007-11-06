require File.dirname(__FILE__) + '/../test_helper'

class SessionTest < Test::Unit::TestCase
  fixtures :sessions

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  #test invalid session id
  def test_invalid_session_id
    a=Session.new
    a.session_id="AnInvalidSessionId"
    assert_raise(ActiveRecord::RecordInvalid){a.save!}
  end
  
  #test invalid host
  def test_invalid_host
    a=Session.new
    a.session_id="#{'0'*32}"
    a.host="AnInvalidHost"
    assert_raise(ActiveRecord::RecordInvalid){a.save!}
  end
end
