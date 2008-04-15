require File.dirname(__FILE__) + '/../spec_helper'

describe Project, 'when some user just applied' do
  fixtures :projects, :users, :roles, :roles_users
  
  before(:each) do
    @project = Project.apply(Project.find(:first).attributes, User.find(:first))
  end

  it "could be approved" do
    @project.approve('this is unit testing!')
    @project.status.should == Project::STATUS[:READY]
  end

  it "should be invalid to be approved/rejected at wrong states" do
    (1..3).to_a.each do |i| #not in :APPLYING state
      @project.status = i
      #@project.approve('this is unit testing!').should raise_error
      #@project.reject('this is unit testing!').should raise_error
    end
  end

  it "could be rejected" do
    @project.reject('this is unit testing!')
    @project.status.should == Project::STATUS[:REJECTED]
  end
end

describe Project, "when approved" do
  fixtures :projects, :users, :roles, :roles_users
  
  before(:each) do
    @project = Project.apply(Project.find(:first).attributes, User.find(:first))
    @project.approve('this is unit testing!')
  end
  
  it "could be suspended" do
    @project.suspend('this is unit testing!')
    @project.status.should == Project::STATUS[:SUSPENDED]
  end
  
  it "could be resumed" do
    @project.suspend('this is unit testing!')
    @project.resume('this is unit testing!')
    @project.status.should == Project::STATUS[:READY]
  end
  
  it "should be invalid to be suspended/resumed at wrong states" do
    ( (0..3).to_a - [2] ).each do |i| #not in :READY state
      @project.status = i
      #@project.suspend('this is unit testing!').should raise_error
    end
    
    ( (0..3).to_a - [3] ).each do |i| #not in :SUSPENDED state
      @project.status = i
      #@project.resume('this is unit testing!').should raise_error
    end
  end
end
