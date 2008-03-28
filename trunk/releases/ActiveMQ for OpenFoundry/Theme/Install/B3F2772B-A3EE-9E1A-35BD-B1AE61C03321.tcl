proc CreateWindow.B3F2772B-A3EE-9E1A-35BD-B1AE61C03321 {wizard id} {
    CreateWindow.CustomBlankPane2 $wizard $id

    set base [$id widget get ClientArea]

    grid rowconfigure    $base 0 -weight 1
    grid columnconfigure $base 0 -weight 1

    set frame [frame $base.frame]
    grid $frame -row 0 -column 0 -sticky new -padx 10

    grid rowconfigure    $frame 0 -weight 1
    grid columnconfigure $frame 0 -weight 1

    ttk::entry $frame.passwordE -textvariable ::info([$id get VirtualText])
    grid $frame.passwordE -row 0 -column 0 -sticky new
    $id widget set PasswordEntry -widget $frame.passwordE -type entry

    ttk::entry $frame.passwordC -textvariable ::info([$id get VirtualText])
    grid $frame.passwordC -row 2 -column 0 -sticky new
    $id widget set PasswordEntry -widget $frame.passwordC -type entry

    if {[$id get HidePassword]} {
        $frame.passwordE configure -show *
    }
    $frame.passwordC configure -show *
}

