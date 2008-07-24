# Any configuration directives you include  here will override 
# RT's default configuration file, RT_Config.pm
#
# To include a directive here, just copy the equivalent statement
# from RT_Config.pm and change the value. We've included a single
# sample value below.
#
# This file is actually a perl module, so you can include valid
# perl code, as well.
#
# The converse is also true, if this file isn't valid perl, you're
# going to run into trouble. To check your SiteConfig file, use
# this comamnd:
#
#   perl -c /path/to/your/etc/RT_SiteConfig.pm

Set($rtname, 'OSSF');
Set($Organization, $rtname);
Set($TicketBaseURI, "fsck.com-rt://$RT::rtname/ticket/");
Set($WebURL, "http://of.openfoundry.org/rt/");

#Set($LogToFile      , 'debug');
#Set($LogDir, '/tmp');
Set($OpenFoundry_SSO, 1);
Set($OpenFoundry_SSO_Cookie, '_of_session_id');
Set($OpenFoundry_SSO_URL, 'http://of.openfoundry.org/openfoundry/get_user_by_session_id?session_id='); 
Set($DatabaseRTHost, '192.168.0.30');

# If you're putting the web ui somewhere other than at the root of
# your server, you should set $WebPath to the path you'll be
# serving RT at.
# $WebPath requires a leading / but no trailing /.
#
# In most cases, you should leave $WebPath set to '' (an empty value).

Set($WebPath , "/rt");
#Set($WebBaseURL, "http://rt.of.openfoundry.org");

1;
