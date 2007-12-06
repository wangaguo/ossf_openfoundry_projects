module ProjectsHelper
  def of_check_box_group(name, predefined, value)
    value ||= ""
    rtn = ""
    predefined.each_with_index do |p, i|
      rtn += check_box_tag("#{name}[#{i}]", p, value.split(",").include?(p)) + p + "\n"
    end
    rtn += "<br/> Others "
    rtn += text_field_tag("#{name}[-1]", (value.split(",") - predefined).join(","))
  end
end 
