#!/usr/local/bin/perl
##
##  printenv -- demo CGI program which just prints its environment
##

print "Content-type: text/html; charset=utf-8\n\n";
#foreach $var (sort(keys(%ENV))) {
#    $val = $ENV{$var};
#    $val =~ s|\n|\\n|g;
#    $val =~ s|"|\\"|g;
#    print "${var}=\"${val}\"\n";
#}
$val = $ENV{'HTTP_HOST'};
$val =~ s|([^.]+)\..+|\1|g;
#print $val;
print '<meta http-equiv="content-type" content="text/html; charset=UTF-8">';
print '<meta http-equiv="refresh" content="10;URL=http://of.openfoundry.org/projects/'.$val.'">';
print 'This is a default page generated for project "'.$val.'" by WebHosting service.<br /> If you are the administrator of this project, you can upload web pages to this site.<br />';
print 'Click <a href="http://of.openfoundry.org/projects/'.$val.'">Here</a> to return Project <a href="http://of.openfoundry.org/projects/'.$val.'">'.$val.'</a>';
