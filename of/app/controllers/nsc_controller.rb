class NscController < ApplicationController
  def index
  end
  def download_count

  end
  def report_status
    @project_name_to_files = {}
    Dir.glob("#{NSC_UPLOAD_DIR}/*") do |path|
      basename = File.basename(path)
      if basename.match(/(.*?)_/)
        (@project_name_to_files[$1] ||= []) << basename
      end
    end
  end

  def nscid2name
    nsc_file = File.join(Rails.root, "config", "nscid2name.txt")
    nsc_data = []
    nsc_find = ""
  
    File.open(nsc_file).each_line("\n") do |line|
      line.gsub!(/\n/, "")
      nsc_data << line.split(",")
    end

    nsc_data.each do |row|
      ps = Project.find_tagged_with("NSC#{row[3]}")
      find = ""
      has_project = 0
      ps.each do |p|
        if p.status == Project::STATUS[:READY] || p.status == Project::STATUS[:APPLYING] || p.status == Project::STATUS[:PENDING]
          find += "<br/>" if has_project != 0 
          find += "#{p.name}"
          find += "(#{Project.status_to_s(p.status)})" if p.status != Project::STATUS[:READY]
          has_project += 1
        end
      end
      if has_project == 0
        find += "none"
      end
      row << find
    end
    @nsc_data = nsc_data 
  end
end
