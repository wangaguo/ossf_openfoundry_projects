module ProjectsHelper
  def cc_images(license) # int
    rtn = ""
    case license
    when 2: ["by", "nc", "nd"]
    when 3: ["by", "nc", "sa"]
    when 4: ["by", "nc"      ]
    when 5: ["by",       "nd"]
    when 6: ["by",       "sa"]
    when 7: ["by"            ]
    else []
    end.each do |x|
      rtn += " <img src=\"/images/cc/#{x}_standard.gif\" width=\"16\">"
    end
    rtn
  end
end
