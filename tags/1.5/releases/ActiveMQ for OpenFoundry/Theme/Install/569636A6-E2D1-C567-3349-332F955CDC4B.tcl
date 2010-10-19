proc CreateWindow.569636A6-E2D1-C567-3349-332F955CDC4B {wizard id} {
    CreateWindow.CustomBlankPane2 $wizard $id

    set base [$id widget get ClientArea]

    grid rowconfigure    $base 0 -weight 1
    grid columnconfigure $base 0 -weight 1

    set frame [frame $base.frame]
    grid $frame -row 0 -column 0 -sticky new

    grid rowconfigure    $frame 0 -weight 1
    grid columnconfigure $frame 0 -weight 1

    label $frame.userLabel -anchor w -padx 0
    grid  $frame.userLabel -row 0 -column 0 -sticky w -pady 5
    $id widget set UserNameLabel -widget $frame.userLabel

    entry $frame.userEntry -textvariable info(UserInfoName)
    grid  $frame.userEntry -row 1 -column 0 -sticky ew

    label $frame.codeLabel -anchor w -padx 0
    grid  $frame.codeLabel -row 2 -column 0 -sticky w -pady 5
    $id widget set CompanyLabel -widget $frame.codeLabel

    entry $frame.codeEntry -textvariable info(UserInfoPasscode)
    grid  $frame.codeEntry -row 3 -column 0 -sticky ew
}

