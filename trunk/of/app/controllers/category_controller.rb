class CategoryController < ApplicationController

  def open
	@category=Category.find params[:id]
  	@contents=Category.find(:all,:conditions => [ "parent=?",params[:id] ] )
	render :layout => false
  end

  def close
	@category=Category.find params[:id]
	render :layout => false
  end

  def index
    list
    render :template => 'category/list'
  end
  
  def list
    @module_name = _('Project Category')
#    #projects = Project.find(:all, :conditions => Project::in_used_projects())
#    @maturity = {}
#    @license = {}
#    @content_license = {}
#    @platform = {}
#    @programming_language = {}
#    
#    Project.in_used.each do |p|
#      [p.maturity].each{|x| @maturity[x] = (@maturity[x] || 0) + 1}
#      "#{p.license}".split(",").grep(/./).each{|x| @license[x] = (@license[x] || 0) + 1}
#      "#{p.contentlicense}".split(",").grep(/./).each{|x| @content_license[x] = (@content_license[x] || 0) + 1}
#      "#{p.platform}".split(",").grep(/./).each{|x| @platform[x] = (@platform[x] || 0) + 1}
#      "#{p.programminglanguage}".split(",").grep(/./).each{|x| @programming_language[x] = (@programming_language[x] || 0) + 1}
    reset_sortable_columns
    add_to_sortable_columns( 'listing', :name, 'name' )
    add_to_sortable_columns( 'listing', :summary, 'summary' )
    add_to_sortable_columns( 'listing', :category, 'category' )
    add_to_sortable_columns( 'listing', :created_at, 'created_at' )
    @sortable = sortable_order('listing', :field => 'updated_at', :sort_direction => :desc)

    start_time = DateTime.now
		# all used projects
		@all_projects = Project.search('', :order => @sortable, :sort_mode => :extended)
		@all_projects_count = @all_projects.total_entries

    @pcs_projects_conditions = {} 

		# with category filter
    params[ :cat ] = '0' if params[ :cat ].blank?
    @pcs_projects = @all_projects

    @pcs_projects_conditions[:nsc_tag] = '*NSC*' if params[:nsc_or_not] == 'true'

		# with search filter
    keyword = params[ :cat_query ]
    query = keyword || ""
    @pcs_projects_conditions[:category] = params[:cat] unless params[:cat] == '0'

		#thinking_sphinx setting:    max_matches:10000/per_page:20=500
		params[:page] = 1 if (params[:page].to_i > 500)

    #process the keywords like "key words" output to "*key* *words*"
    query = (query+" ").gsub(/([a-z0-9])+[\s]+/i){|m|
      $0 = ""; m.scan(/[a-z]+|\d+/i).each{|q| q.match(/^[a-z]+$/i)? $0+=" *#{q}* " : $0+=" #{q} "}; $0;}

    @pcs_projects = Project.search( Riddle.escape(query), :page => params[:page], :per_page => 20, :conditions => @pcs_projects_conditions ,:order => @sortable)
    @pcs_projects_count = @pcs_projects.total_entries
    #			@pcs_projects = @pcs_projects.find(:all, :conditions => ["name LIKE ? OR summary LIKE ? OR description LIKE ? OR programminglanguage LIKE ? OR platform LIKE ?", "%#{params[:cat_query]}%", "%#{params[:cat_query]}%", "%#{params[:cat_query]}%", "%#{params[:cat_query]}%", "%#{params[:cat_query]}%"], :order => sortable_order( 'listing', :field => 'name', :sort_direction => :asc ))

    # increase the search times for tags
    Tagcloud.increase_searched_tag( keyword ) if session[ :search_keyword ] != keyword
    session[ :search_keyword ] = keyword

		# with nsc filter
#    if params[ :nsc_or_not ] == 'true'
#      if params[:cat_query].blank?
#        @pcs_projects = @pcs_projects.find(:all, :order => sortable_order( 'listing'))
#        @pcs_projects = @pcs_projects.select(&:is_nsc_project)
#      else
#        tmp_final_project_list = []
#        @pcs_projects.each {|ep| tmp_final_project_list.push(ep) if ep.is_nsc_project}
#        @pcs_projects = tmp_final_project_list
#      end
#    end

		# with paginate process
#    @final_project_list = nil
#    if params[:cat_query].blank?
#      @final_project_list = @pcs_projects.paginate(
#        :page => params[:page],
#        :per_page => 20,
#        :order => sortable_order( 'listing', :model => Project, :field => 'created_at', :sort_direction => :desc ) ) 
#    else
logger.error @pcs_projects.class
logger.error '========================================================================='
      @final_project_list = @pcs_projects
#    end
    end_time=DateTime.now
    @elapsed_seconds = format("%.2f", (end_time.to_f - start_time.to_f))

   	render :layout => false if request.xhr?
  end

  def show
  end

  def edit
  end

  def create
  end

  def destory
  end
end
