require File.dirname(__FILE__) + '/../spec_helper'

describe Session do
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
