## $Id$
##
## BEGIN LICENSE BLOCK
##
## Copyright (C) 2002  Damon Courtney
## 
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## version 2 as published by the Free Software Foundation.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License version 2 for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the
##     Free Software Foundation, Inc.
##     51 Franklin Street, Fifth Floor
##     Boston, MA  02110-1301, USA.
##
## END LICENSE BLOCK

if {[info exists ::InstallJammer]} { return }

namespace eval ::InstallAPI {}
namespace eval ::InstallJammer {}

set ::debug   "on"
set ::verbose 0

set ::conf(osx)      [string equal $::tcl_platform(os) "Darwin"]
set ::conf(unix)     [string equal $::tcl_platform(platform) "unix"]
set ::conf(windows)  [string equal $::tcl_platform(platform) "windows"]

set ::conf(threaded) [info exists ::tcl_platform(threaded)]

set ::info(Debugging) 0

## Trace the virtual text array for changes and execute any
## attached commands or auto-update actions.
trace add variable ::info write ::InstallJammer::VirtualTextTrace

proc ::InstallJammer::VirtualTextTrace { name1 name2 op } {
    upvar #0 ::info($name2) var

    if {[info exists ::InstallJammer::UpdateVarCmds($name2)]} {
        foreach cmd $::InstallJammer::UpdateVarCmds($name2) {
            uplevel #0 $cmd
        }
    }

    if {[info exists ::InstallJammer::AutoUpdateVars($name2)]
        && $var ne $::InstallJammer::AutoUpdateVars($name2)} {
        set ::InstallJammer::AutoUpdateVars($name2) $var
        ::InstallJammer::UpdateWidgets -updateidletasks 1
    }
}

proc ::InstallJammer::SourceCachedFile { file {namespace "::"} } {
    if {[info exists ::InstallJammer::files($file)]} {
        namespace eval $namespace $::InstallJammer::files($file)
        return 1
    }
    return 0
}

namespace eval ::InstallAPI {}
namespace eval ::InstallJammer {}
set conf(version)     1.2.5
set info(Platform)    FreeBSD-x86
set info(InstallerID) 09ED45A4-BA86-F0BB-E732-E0C672BB8E7F
array set ::InstallJammer::languagecodes {de German en English es Spanish fr French hu Magyar it Italian nl Nederlands pl Polish pt_br {Brazilian Portuguese}}
array set info {
AllowLanguageSelection
Yes

AppName
{OpenFoundry Inside}

ApplicationID
E4469D39-3BAE-3222-1FDB-3A8DD0FA0D26

ApplicationURL
{}

BuildFailureAction
{Fail (recommended)}

BuildVersion
0

CancelledInstallAction
{Rollback and Stop}

CleanupCancelledInstall
Yes

Company
www.openfoundry.org

CompressionMethod
zlib

Copyright
{}

DefaultDirectoryPermission
0755

DefaultFilePermission
0755

DefaultLanguage
English

ExtractSolidArchivesOnStartup
No

FallBackToConsole
Yes

IncludeDebugging
Yes

InstallDir
<%Home%>/<%ShortAppName%>

InstallMode
Standard

InstallType
Typical

InstallVersion
1.0.0.0

MajorVersion
1

MinorVersion
0

PackageDescription
{}

PackageLicense
{}

PackageMaintainer
{}

PackageName
<%ShortAppName%>

PackagePackager
{}

PackageRelease
<%PatchVersion%>

PackageSummary
{}

PackageVersion
<%MajorVersion%>.<%MinorVersion%>

PatchVersion
0

ProgramExecutable
<%InstallDir%>/host

ProgramFolderAllUsers
No

ProgramFolderName
<%AppName%>

ProgramLicense
<%InstallDir%>/LICENSE.txt

ProgramName
{}

ProgramReadme
<%InstallDir%>/README.txt

PromptForRoot
Yes

RequireRoot
No

RootInstallDir
/usr/local/<%ShortAppName%>

ShortAppName
openfoundry

UpgradeApplicationID
{}

Version
1.0

}
array set ::InstallJammer::CommandLineOptions {
debug
{Debugging Switch Yes No {} {run installer in debug mode}}

debugconsole
{ShowConsole Switch Yes No {} {run installer with a debug console open}}

mode
{InstallMode Choice No No {Console Default Silent Standard} {set the mode to run the installer in}}

prefix
{InstallDir String No No {} {set the installation directory}}

test
{Testing Switch Yes No {} {run installer without installing any files}}

}
