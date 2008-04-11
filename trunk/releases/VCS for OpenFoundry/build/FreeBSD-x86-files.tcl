proc ::InstallJammer::InitFiles {} {
    File ::265A9D1F-B262-0049-C27D-9AE4A8D8E51E -name config.sh -parent C73213B8-9061-3CB9-2E6B-4A9C7FFF000F -directory <%InstallDir%> -size 4051 -mtime 1207214464 -permissions 00755 -filemethod "Update files with more recent dates"
    File ::2642F637-B5BB-5A2A-59D8-0015159628AF -name install.sh -parent C73213B8-9061-3CB9-2E6B-4A9C7FFF000F -directory <%InstallDir%> -size 3019 -mtime 1207820171 -permissions 00700 -filemethod "Update files with more recent dates"

}
