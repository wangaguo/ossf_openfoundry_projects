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
    @year = params[:year] || ""
    @type = params[:type] || ""
    @teacher = params[:teacher] || ""

    if @year == ""
      @year = Time.now.year - 1911
      @year -= 1 if Time.now.month < 10
      @year = @year.to_s
    end

    File.open(nsc_file).each_line("\n") do |line|
      line.gsub!(/\n/, "")
      line = line.split(",")
      if @teacher == ""
        if line[0] =~ Regexp.new(@year) and line[1] =~ Regexp.new(@type) then
          nsc_data << line
        end
      else
        if line[3] =~ Regexp.new(@teacher) then
          nsc_data << line
        end
      end
    end

    nsc_data.each do |row|
      ps = Project.find_tagged_with("NSC#{row[4]}")
      find = ""
      has_project = 0
      ps.each do |p|
        if p.status == Project::STATUS[:READY] || p.status == Project::STATUS[:APPLYING] || p.status == Project::STATUS[:PENDING]
          find += "<br/>" if has_project != 0 
          find += "<a href=\"#{root_path}/projects/#{p.name}/\">#{p.name}</a>" 
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
