module ProjectsHelper
  def of_check_box_group(name, predefined, value)
    values = "#{value}".split(",")
    rtn = ""
    predefined = predefined.sort
    predefined.each_with_index do |p, i|
      rtn += check_box_tag("#{name}[#{i}]", p, values.include?(p)) + p + "\n"
    end
    rtn += "<br/> Others "
    rtn += text_field_tag("#{name}[-1]", (values - predefined).join(","))
  end
end 
