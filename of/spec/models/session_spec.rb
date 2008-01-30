require File.dirname(__FILE__) + '/../spec_helper'

describe Session, 'when created' do
  before(:each) do
    @session = Session.new
  end

  it "should have valid session_id" do
    @session.session_id = "AWrongId"
    @session.should have(1).error_on(:session_id)
  end

  it "should have valid host" do
    @session.host = "AWrongHost"
    @session.session_id = '0'*32 #valid session_id
    @session.should have(1).error_on(:host)
  end
end

describe Session, 'when count existed sessions' do
  fixtures :sessions
  
  it "should tell expired sessions" do
    Session.expired_sessions.length.should eql(10)
    Session.count_expired_sessions.should eql(10)
    Session.destroy_expired_sessions!
    Session.expired_sessions.length.should eql(0)
    Session.count_expired_sessions.should eql(0)
  end
  
  it "should tell active sessions" do
    Session.active_sessions.length.should eql(20)
    Session.count_active_sessions.should eql(20)
  end
  
  it "should tell anonymous sessions" do
    Session.anonymous_sessions.length.should eql(10)
    Session.count_anonymous_sessions.should eql(10)
  end
end