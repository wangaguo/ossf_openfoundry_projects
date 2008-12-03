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
end
