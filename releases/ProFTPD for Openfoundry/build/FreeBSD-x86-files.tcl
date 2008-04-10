proc ::InstallJammer::InitFiles {} {
    File ::DEB80E36-1CD1-274D-F640-186CB9BEACAE -name ftp -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%> -size 4096 -mtime 1207722234 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::003128C5-767F-F35E-447D-D2968D6AE335 -name proftpd_with_mysql.conf -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%> -size 3194 -mtime 1207040593 -permissions 00644 -filemethod "Update files with more recent dates"
    File ::45D88B29-21EF-76DD-7B05-1AA8DDE9F897 -name sync_ftp_users.sh -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%> -size 177 -mtime 1207040780 -permissions 00700 -filemethod "Update files with more recent dates"
    File ::CFCB9E5E-00A3-F6D0-BCB0-43684CC0A0B5 -name sync_ftp_users.sql -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%> -size 1476 -mtime 1207639690 -permissions 00644 -filemethod "Update files with more recent dates"
    File ::7DFB3EF6-0812-FD8F-ABBF-4D3F7D05A0C9 -name .svn -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn -size 4096 -mtime 1207718031 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::C93FB581-801E-1EBF-D5C4-99CC1F414F19 -name all-wcprops -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn -size 597 -mtime 1207718031 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::93BEE932-CA01-15A6-05F3-7B83AA5B1569 -name entries -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn -size 787 -mtime 1207718031 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::F9DBC59C-C7BE-802B-2CE1-07A76E790F33 -name format -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn -size 2 -mtime 1207030686 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::5710DD2B-DB38-291E-B4A5-88FBDC084314 -name prop-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/prop-base -size 4096 -mtime 1207041630 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::85C1FC84-8FC5-7C86-2378-425F7AF9096B -name sync_ftp_users.sh.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/prop-base -size 30 -mtime 1207030686 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::F63B05A1-165B-2A14-1A50-EF26B69EC3C0 -name install_rep.sh.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/prop-base -size 30 -mtime 1207041630 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::25F233F5-B35D-5BD1-9DB6-0084AD4620E3 -name props -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/props -size 4096 -mtime 1207041630 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::9F23C031-F0AE-37A3-F25E-3AABFBFFA837 -name text-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/text-base -size 4096 -mtime 1207041630 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::788055D0-C870-63FF-11DB-021B2DCEA4E3 -name proftpd_with_mysql.conf.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/text-base -size 3194 -mtime 1207040593 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::54F3E340-0AEF-FEB4-AAC4-500E39695080 -name sync_ftp_users.sh.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/text-base -size 177 -mtime 1207040780 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::96351DFA-1E5E-7DC6-40C2-5CA8380CC233 -name sync_ftp_users.sql.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/text-base -size 1771 -mtime 1207030686 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::F0F5801F-54F7-095B-725C-27206BDEB18A -name install_rep.sh.svn-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%>/.svn/text-base -size 813 -mtime 1207040631 -permissions 00444 -filemethod "Update files with more recent dates"
    File ::E9249B12-50B2-BB71-D23B-A68FFE150956 -name tmp -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/tmp -size 4096 -mtime 1207718031 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::7F4D9AE1-1DA9-1A4F-048A-E138037D5319 -name prop-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/tmp/prop-base -size 4096 -mtime 1207030686 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::6AB41268-6582-080A-7B9A-AD33F2730EAF -name props -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/tmp/props -size 4096 -mtime 1207041630 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::291EA41E-B76A-E19F-E85E-ECD9152B2391 -name text-base -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -type dir -directory <%InstallDir%>/.svn/tmp/text-base -size 4096 -mtime 1207041630 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::733EA2DA-1176-96A0-35B2-BDD564AE8674 -name install_rep.sh -parent DCB7EB11-1E99-8A2D-228F-B8758262DFC5 -directory <%InstallDir%> -size 813 -mtime 1207040631 -permissions 00700 -filemethod "Update files with more recent dates"

}
