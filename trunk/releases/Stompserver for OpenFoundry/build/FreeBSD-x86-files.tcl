proc ::InstallJammer::InitFiles {} {
    File ::B406A6AB-1F5C-0DD3-EEBD-5BB4F3C6FCEF -name stompserver -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -type dir -directory <%InstallDir%> -size 4096 -mtime 1206953688 -permissions 040755 -filemethod "Update files with more recent dates"
    File ::505507FC-FDD9-B5E3-2448-4EEF869F29AA -name .passwd -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -directory <%InstallDir%> -size 193 -mtime 1206932201 -permissions 00644 -filemethod "Update files with more recent dates"
    File ::79AA37F7-A0A1-84D5-6A5A-641BBB1EB74D -name install_ruby.sh -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -directory <%InstallDir%> -size 2451 -mtime 1206952015 -permissions 00700 -filemethod "Update files with more recent dates"
    File ::C2C2A42B-A466-0DBC-D477-5A05E2D3C9F3 -name stompserver.conf -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -directory <%InstallDir%> -size 148 -mtime 1206932153 -permissions 00644 -filemethod "Update files with more recent dates"
    File ::63DB80A3-C445-657A-9E09-3214368DC5E7 -name stompserver -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -directory <%InstallDir%> -size 662 -mtime 1206934023 -permissions 00755 -filemethod "Update files with more recent dates"
    File ::B643137E-D6DD-B404-1715-4DD70949D371 -name stompserver.sh -parent 25AD9916-293E-E4C0-F14E-E07F7284A462 -directory <%InstallDir%> -size 181 -mtime 1206953684 -permissions 00700 -filemethod "Update files with more recent dates"

}
