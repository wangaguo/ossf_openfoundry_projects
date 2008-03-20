require 'rubygems'
require 'activerecord'


class RTModel < ActiveRecord::Base
  self.abstract_class = true  # This isn't a model itself
  #self.establish_connection :rt  #

#  def self.sync_with_of(projects, users, relations)
#    puts "1111111111111 #{Time.now}"
#    RTModel.transaction do
#      projects.each do |p|
#        RTQueue.create_queue(p[:id],p[:name],p[:desc])
#      end
#      users.each do |u|
#        RTUser.create_user(u[:id],u[:name])
#      end
#      relations.each do |r|
#        RTUser.create_relation(r[:uid],r[:pid],r[:type])
#      end
#    end
#    puts "2222222 #{Time.now}"
#  end
end

class RTQueue < RTModel
  set_table_name 'Queues'
  def initialize(options)
    t = Time.now # TODO: Time.now.utc ?
    super({
      #:Name =>           | varchar(200) | NO   | UNI | NULL    |                | 
      #:Description       | varchar(255) | YES  |     | NULL    |                | 
      #:CorrespondAddress | varchar(120) | YES  |     | NULL    |                | 
      #:CommentAddress    | varchar(120) | YES  |     | NULL    |                | 
      #:InitialPriority   | int(11)      | NO   |     | 0       |                | 
      #:FinalPriority     | int(11)      | NO   |     | 0       |                | 
      #:DefaultDueIn      | int(11)      | NO   |     | 0       |                | 
      :Creator => 12,#          | int(11)      | NO   |     | 0       |                | 
      :Created => t,#          | datetime     | YES  |     | NULL    |                | 
      :LastUpdatedBy => 12,#    | int(11)      | NO   |     | 0       |                | 
      :LastUpdated => t #      | datetime     | YES  |     | NULL    |                | 
      #:Disabled

    }.merge(options))
    self.id = options[:id]

  end

  def self.create_queue(id,name,desc)
    RTQueue.new(:id => id, :Name => name, :Description => desc).save
    %w(Owner Cc AdminCc Requestor).each do |type|
      gid = RTPrincipal.create_group(
        :Domain => "RT::Queue-Role",
        :Type => type,
        :Instance => id).id

      RTCachedGroupMember.new(:GroupId => gid, :MemberId => gid,
                              :ImmediateParentId => gid).via  
    end
  end

  # TODO: generate sql update statement directly
  def self.update_queue(id, desc)
    RTQueue.update(id, :Description => desc, :LastUpdated => Time.now)
  end
end

class RTGroupMember < RTModel
  set_table_name 'GroupMembers'
end

class RTCachedGroupMember < RTModel
  set_table_name 'CachedGroupMembers'
  def initialize(options)
    super(options)
  end
  def via
    self.save
    self.Via = self.id
    self.save
  end

end

class RTGroup < RTModel
  set_table_name 'Groups'
  #  `id` int(11) NOT NULL auto_increment,
  #  `Name` varchar(200) default NULL,
  #  `Description` varchar(255) default NULL,
  #  `Domain` varchar(64) default NULL,
  #  `Type` varchar(64) default NULL,
  #  `Instance` int(11) default NULL,

  def initialize(options)
    super(options)
    self.id = options[:id]
  end

  def self.equiv_group_options(uid)
    {
      :Name => "User #{uid}",
      :Description => "ACL equiv. for user #{uid}",
      :Domain => "ACLEquivalence",
      :Type => "UserEquiv",
      :Instance => uid
    }
  end

end

class RTPrincipal < RTModel
  set_table_name 'Principals'
  #  `id` int(11) NOT NULL auto_increment,
  #  `PrincipalType` varchar(16) NOT NULL,
  #  `ObjectId` int(11) default NULL,
  #  `Disabled` smallint(6) NOT NULL default '0',

  def self.create_user(options) # set id / name here!
    p = RTPrincipal.new(:PrincipalType => 'User', :ObjectId => options[:id], :Disabled => (options[:Disabled] || 0))
    p.id = options[:id]
    p.save

    options.delete(:Disabled)

    u = RTUser.new(options)
    u.save
    u
  end
  def self.create_group(options) # don't set id here!
    p = RTPrincipal.new(:PrincipalType => 'Group', :Disabled => (options[:Disabled] || 0))
    p.save
    p.ObjectId = p.id
    p.save

    options.delete(:Disabled)

    g = RTGroup.new(options.merge(:id => p.id))
    g.save
    g
  end
   
    

end

class RTUser < RTModel
  set_table_name 'Users'

#  def self.create_user(id, name)
  def initialize(options)
    t = Time.now
    options = {
#      :id` int(11) NOT NULL auto_increment,
      :Name => options[:Name], #` varchar(200) NOT NULL,
      :Password => '*NO-PASSWORD*', #` varchar(40) default NULL,
      :Comments => '', #` blob,
#      :Signature` blob,
      :EmailAddress => '', #` varchar(120) default NULL,
      :FreeformContactInfo => '', #` blob,
      :Organization => '', #` varchar(200) default NULL,
      :RealName => '', #` varchar(120) default NULL,
      :NickName => '', #` varchar(16) default NULL,
      :Lang => '', #` varchar(16) default NULL,
#      :EmailEncoding` varchar(16) default NULL,
#      :WebEncoding` varchar(16) default NULL,
#      :ExternalContactInfoId` varchar(100) default NULL,
#      :ContactInfoSystem` varchar(30) default NULL,
#      :ExternalAuthId` varchar(100) default NULL,
#      :AuthSystem` varchar(30) default NULL,
      :Gecos => '', #` varchar(16) default NULL,
      :HomePhone => '', #` varchar(30) default NULL,
      :WorkPhone => '', #` varchar(30) default NULL,
      :MobilePhone => '', #` varchar(30) default NULL,
      :PagerPhone => '', #` varchar(30) default NULL,
      :Address1 => '', #` varchar(200) default NULL,
      :Address2 => '', #` varchar(200) default NULL,
      :City => '', #` varchar(100) default NULL,
      :State => '', #` varchar(100) default NULL,
      :Zip => '', #` varchar(16) default NULL,
      :Country => '', #` varchar(50) default NULL,
#      :Timezone` varchar(50) default NULL,
#      :PGPKey` text,
      :Creator => 12, #` int(11) NOT NULL default '0',
      :Created => t, #` datetime default NULL,
      :LastUpdatedBy => 12, #` int(11) NOT NULL default '0',
      :LastUpdated => t #` datetime default NULL,
    }.merge(options)
    super(options)
    self.id = options[:id]
  end
  
  def self.create_relation(uid, pid, type)
    #p uid,pid,type
    case type
    when 'Admin'
      type = 'AdminCc'
    when 'Member'
      type = 'Cc'
    else
      return
    end
    gid = RTGroup.find(:first, :conditions => "Type = '#{type}' and Instance = #{pid}").id
    cache_id = RTCachedGroupMember.find(:first, :conditions => "MemberId = #{gid}").id

    RTGroupMember.new(:GroupId => gid, :MemberId => uid).save
    RTCachedGroupMember.new(:GroupId => gid, :MemberId => uid, :ImmediateParentId => gid).via
    RTCachedGroupMember.new(:GroupId => gid, :MemberId => uid, :Via => cache_id, :ImmediateParentId => gid).save
  end
  def self.delete_relation(uid, pid, type)
    #p uid,pid,type
    case type
    when 'Admin'
      type = 'AdminCc'
    when 'Member'
      type = 'Cc'
    else
      return
    end
    gid = RTGroup.find(:first, :conditions => "Type = '#{type}' and Instance = #{pid}").id
    #cache_id = RTCachedGroupMember.find(:first, :conditions => "MemberId = #{gid}").id

    # TODO: accuracy ?
    RTCachedGroupMember.delete_all("GroupId = #{gid} and MemberId = #{uid} and ImmediateParentId = #{gid}")
    RTGroupMember.delete_all("GroupId = #{gid} and MemberId = #{uid}")
  end

  def self.create_user(id, name)
    RTPrincipal.create_user(:id => id, :Name => name)

    equiv_gid = RTPrincipal.create_group(RTGroup.equiv_group_options(id)).id
    
    RTGroupMember.new(:GroupId => equiv_gid, :MemberId => id).save
    RTGroupMember.new(:GroupId => 3, :MemberId => id).save
    RTGroupMember.new(:GroupId => 4, :MemberId => id).save
    
    RTCachedGroupMember.new(:GroupId => equiv_gid, :MemberId => equiv_gid,  :ImmediateParentId => equiv_gid).via

    RTCachedGroupMember.new(:GroupId => equiv_gid, :MemberId => id,  :ImmediateParentId => equiv_gid).via
    RTCachedGroupMember.new(:GroupId => 3, :MemberId => id,  :ImmediateParentId => 3).via
    RTCachedGroupMember.new(:GroupId => 3, :MemberId => id, :Via => 3, :ImmediateParentId => 3).save
    RTCachedGroupMember.new(:GroupId => 4, :MemberId => id,  :ImmediateParentId => 4).via
    RTCachedGroupMember.new(:GroupId => 4, :MemberId => id, :Via => 4, :ImmediateParentId => 4).save
  end

  # TODO: generate sql update statement directly
  def self.update_user(id, name, email)
    RTUser.update(id, :EmailAddress => email, :LastUpdated => Time.now)
  end
end


