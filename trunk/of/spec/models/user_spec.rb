require File.dirname(__FILE__) + '/../spec_helper'

describe User, 'when created' do
  before(:each) do
     @user = User.new
  end
 
  it "should have valid login" do
    @user.email='some@go.where.sky' #valid email    

    @user.login='' #empty, and too short
    @user.save
    @user.should have(2).error_on(:login)

    @user.login='x'*41 #longer than 40
    @user.save
    @user.should have(1).error_on(:login)

    @user.login='aa' #shorter than 3
    @user.save
    @user.should have(1).error_on(:login)

  end  

  it 'should have valid email' do
    @user.login='test' #valid login name
    
    @user.email='' #empty email
    @user.save
    @user.should have(1).error_on(:email)

    @user.email='invalid_email@address' #invalid email
    @user.save
    @user.should have(1).error_on(:email)
  end
end

describe User, 'who registed' do
  fixtures :users

  before(:each) do
    @u = User.find(users(:tim).id)
    @tim = users(:tim)
  end
  
  it "could login with name and password" do
    User.authenticate(@tim.login, '123456').should eql(@tim) 
  end
 
  it "should fail with wrong name and password" do
    User.authenticate('blah','blahblah').should be_nil
  end
  
  it "could login with security token" do
    token = @u.generate_security_token
    User.authenticate_by_token(@tim.id, token).should eql(@tim)
  end

  it "should fail with wrong security token" do
    User.authenticate_by_token('blah','blahblahXDXD').should be_nil
  end

  it "could chagne valid password" do
    pass = '000111'	  
    @u.change_password(pass, pass)
    @u.save
    @u.should have(:no).error_on(:password)
    User.authenticate(@tim.login,pass).should eql(@tim)
  end

  it "could change another email" do
    email = 'abc@fish.dog.cat'
    @u.change_email(email, email)
    @u.save
    @u.should have(:no).error_on(:email)
  end

  it "could be set disabled" do
    pending
  end
  
  it "could be set enabled" do
    pending	  
  end
end
