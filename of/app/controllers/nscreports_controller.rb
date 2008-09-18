class NscreportsController < ApplicationController
  layout 'module'
  #find_resources :parent => 'project', :child => 'job', :parent_id_method => 'project_id', :child_rename => 'data_item'
  #before_filter :controller_load
  #before_filter :check_permission
  
  def is_reviewer(user, project_name)
    l = "#{project_name} #{user}\n" # DOS ?
    File.open("#{NSC_UPLOAD_DIR}/reviewers.txt").each do |line|
      return true if line == l
    end
    return false
  end
  before_filter :common
  def common
    @project = Project.find(params[:project_id])
    @nsc_role = @project.nsc_role(current_user)
    case @nsc_role
    when "PI"
      @types_write = ["requirement", "design", "testing"]
    when "REVIEWER"
      @types_write = ["requirement-review-form", "requirement-review-content", "design-review-form", "design-review-content", "testing-review-form", "testing-review-content"]
    when "ADMIN"
      @types_write = []
    else
      @types_write = []
    end
  end

  def index
    if params[:file]
      show
    else
      @files = Dir.glob("#{NSC_UPLOAD_DIR}/#{@project.name}_*")
    end
  end

  def show
    file = params[:file]
    full_path = NSC_UPLOAD_DIR + "/" + file

    if File.basename(file) != file
      render :text => "bad file name"
    elsif matched = file.match(/^([^_]+)_(\d+)_([^_]+)(?:_(.+))?\.(?:pdf|doc)$/)
      (project_name, year, type, author) = matched.to_a[1..-1]
      if project_name == @project.name
        # check type (with author)
        type_ok = false
        err_msg = ""
        if @nsc_role == "ADMIN"
          type_ok = true
        elsif @nsc_role == "PI"
          if type =~ /review/
            if NSC_REVIEW_OPENED
              type_ok = true
            else
              type_ok = false #TODO: year
              err_msg = "PI may not read reviews at this time"
            end
          else
            type_ok = true
          end
        elsif @nsc_role = "REVIEWER"
          if type =~ /review/
            if NSC_REVIEW_OPENED
              type_ok = true
            else
              if current_user.login == author
                type_ok = true
              else
                type_ok = false #TODO: year
                err_msg = "Reviewer can only read his/her own review at this time"
              end
            end
          else
            type_ok = true
          end
        else
          type_ok = false
          err_msg = "Only ADMIN/PIs/Reviewers of the project may read reports/reviews"
        end

        if type_ok
          #render :text => "project_name: #{project_name} year: #{year} type: #{type} author: #{author}"

          send_file full_path # TODO: use X-Sendfile
        else
          render :text => "error: #{err_msg}"
        end
      else
        render :text => "project name not matched"
      end
    else
      render :text => "bad file name format"
    end
  end
  def new
  end
  
  def create
    year = params[:year]
    if year != NSC_CURRENT_YEAR
      render :text => "bad year"
      return
    end

    type = params[:type]
    if not @types_write.include?(type)
      render :text => "you may not write this type of file"
      return
    end

    #render :text => params["the_file"]["datafile"].original_filename
    # ignore orignial_filename
    ext = (type =~ /review/) ? "doc" : "pdf"
    filename = "#{@project.name}_#{year}_#{type}_#{current_user.login}.#{ext}";
    filepath = "#{NSC_UPLOAD_DIR}/#{filename}"
    File.open(filepath, "wb") do |f|
      f.write(params["the_file"].read)
    end
    flash[:notice] = "You have successfully uploaded file: #{filename}"
    redirect_to :action => "index"
  end
end

