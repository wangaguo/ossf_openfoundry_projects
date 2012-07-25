class AddLicensesData < ActiveRecord::Migration
  def self.up
    License.create( :name => 'This project contains no code', :url => '' ,:domain => 'code')
    License.create( :name => 'Public Domain', :url => '' ,:domain => 'code content')
    License.create( :name => 'Other licenses', :url => '' ,:domain => 'code content')
    
    License.create( :name => "OSI: Academic Free License",:url => "url_link_for_OSI: Academic Free License" ,:domain => 'code') 
    License.create( :name => "OSI: Affero GNU Public License",:url => "url_link_for_OSI: Affero GNU Public License" ,:domain => 'code') 
    License.create( :name => "OSI: Adaptive Public License ",:url => "url_link_for_OSI: Adaptive Public License " ,:domain => 'code') 
    License.create( :name => "OSI: Apache License 2.0",:url => "url_link_for_OSI: Apache License 2.0" ,:domain => 'code') 
    License.create( :name => "OSI: Artistic License 2.0",:url => "url_link_for_OSI: Artistic License 2.0" ,:domain => 'code') 
    License.create( :name => "OSI: Attribution Assurance Licenses",:url => "url_link_for_OSI: Attribution Assurance Licenses" ,:domain => 'code') 
    License.create( :name => "OSI: BSD License (New and Simplified BSD License,:domain => 'code')",:url => "url_link_for_OSI: BSD License (New and Simplified BSD License,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Boost Software License (BSL1.0,:domain => 'code')",:url => "url_link_for_OSI: Boost Software License (BSL1.0,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Common Development and Distribution License (CDDL,:domain => 'code')",:url => "url_link_for_OSI: Common Development and Distribution License (CDDL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Common Public Attribution License 1.0 (CPAL,:domain => 'code')",:url => "url_link_for_OSI: Common Public Attribution License 1.0 (CPAL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Common Public License 1.0",:url => "url_link_for_OSI: Common Public License 1.0" ,:domain => 'code') 
    License.create( :name => "OSI: Eclipse Public License",:url => "url_link_for_OSI: Eclipse Public License" ,:domain => 'code') 
    License.create( :name => "OSI: Educational Community License 2.0",:url => "url_link_for_OSI: Educational Community License 2.0" ,:domain => 'code') 
    License.create( :name => "OSI: Eiffel Forum License 2.0",:url => "url_link_for_OSI: Eiffel Forum License 2.0" ,:domain => 'code') 
    License.create( :name => "OSI: Fair License",:url => "url_link_for_OSI: Fair License" ,:domain => 'code') 
    License.create( :name => "OSI: GNU General Public License 2.0 (GPLv2,:domain => 'code')",:url => "url_link_for_OSI: GNU General Public License 2.0 (GPLv2,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: GNU General Public License 3.0 (GPLv3,:domain => 'code')",:url => "url_link_for_OSI: GNU General Public License 3.0 (GPLv3,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: GNU Library or \"Lesser\" General Public License 2.1 (LGPLv2,:domain => 'code')",:url => "url_link_for_OSI: GNU Library or \"Lesser\" General Public License 2.1 (LGPLv2,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: GNU Library or \"Lesser\" General Public License 3.0 (LGPLv3,:domain => 'code')",:url => "url_link_for_OSI: GNU Library or \"Lesser\" General Public License 3.0 (LGPLv3,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: ISC License",:url => "url_link_for_OSI: ISC License" ,:domain => 'code') 
    License.create( :name => "OSI: Lucent Public License 1.02",:url => "url_link_for_OSI: Lucent Public License 1.02" ,:domain => 'code') 
    License.create( :name => "OSI: Microsoft Public License (Ms-PL,:domain => 'code')",:url => "url_link_for_OSI: Microsoft Public License (Ms-PL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Microsoft Reciprocal License (Ms-RL,:domain => 'code')",:url => "url_link_for_OSI: Microsoft Reciprocal License (Ms-RL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: MIT License",:url => "url_link_for_OSI: MIT License" ,:domain => 'code') 
    License.create( :name => "OSI: Mozilla Public License 1.1 (MPL,:domain => 'code')",:url => "url_link_for_OSI: Mozilla Public License 1.1 (MPL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: NASA Open Source Agreement 1.3",:url => "url_link_for_OSI: NASA Open Source Agreement 1.3" ,:domain => 'code') 
    License.create( :name => "OSI: NTP License",:url => "url_link_for_OSI: NTP License" ,:domain => 'code') 
    License.create( :name => "OSI: Open Group Test Suite License",:url => "url_link_for_OSI: Open Group Test Suite License" ,:domain => 'code') 
    License.create( :name => "OSI: Open Software License",:url => "url_link_for_OSI: Open Software License" ,:domain => 'code') 
    License.create( :name => "OSI: Qt Public License (QPL,:domain => 'code')",:url => "url_link_for_OSI: Qt Public License (QPL,:domain => 'code')" ,:domain => 'code') 
    License.create( :name => "OSI: Simple Public License 2.0",:url => "url_link_for_OSI: Simple Public License 2.0" ,:domain => 'code') 
    License.create( :name => "OSI: Sleepycat License",:url => "url_link_for_OSI: Sleepycat License" ,:domain => 'code') 
    License.create( :name => "OSI: University of Illinois/NCSA Open Source License",:url => "url_link_for_OSI: University of Illinois/NCSA Open Source License" ,:domain => 'code') 
    License.create( :name => "OSI: zlib/libpng License",:url => "url_link_for_OSI: zlib/libpng License" ,:domain => 'code') 


    License.create( :name => "Project contains only code",:url => "url_link_for_Project contains only code", :domain => "content" ) 
    License.create( :name => "Same license as code",:url => "url_link_for_Same license as code", :domain => "content" ) 
    License.create( :name => "GNU Free Documentation License",:url => "url_link_for_GNU Free Documentation License", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution Non-commercial No Derivatives (by-nc-nd)",:url => "url_link_for_Creative Commons: Attribution Non-commercial No Derivatives (by-nc-nd)", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution Non-commercial Share Alike (by-nc-sa)",:url => "url_link_for_Creative Commons: Attribution Non-commercial Share Alike (by-nc-sa)", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution Non-commercial (by-nc)",:url => "url_link_for_Creative Commons: Attribution Non-commercial (by-nc)", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution No Derivatives (by-nd)",:url => "url_link_for_Creative Commons: Attribution No Derivatives (by-nd)", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution Share Alike (by-sa)",:url => "url_link_for_Creative Commons: Attribution Share Alike (by-sa)", :domain => "content" ) 
    License.create( :name => "Creative Commons: Attribution (by)",:url => "url_link_for_Creative Commons: Attribution (by)", :domain => "content" ) 
  end

  def self.down
    License.delete_all
  end
end
