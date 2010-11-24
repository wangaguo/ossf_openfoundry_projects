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
    add_to_sortable_columns( 'listing', Project, 'name', 'name' )
    add_to_sortable_columns( 'listing', Project, 'summary', 'summary' )
    add_to_sortable_columns( 'listing', Project, 'category', 'category' )
    add_to_sortable_columns( 'listing', Project, 'created_at', 'created_at' )

		# all used projects
		@pcs_projects = Project.in_used

		# with category filter
    params[ :cat ] = '0' if params[ :cat ].blank?
    @pcs_projects = @pcs_projects.cated( params[ :cat ] )

		# with search filter
		unless params[ :cat_query ].blank?
			keyword = params[ :cat_query ]
			query = ( keyword + ' ' ).gsub( /([a-z0-9])+[\s]+/i ) { | m |
				$0 = '';
			  m.scan( /[a-z]+|\d+/i ).each{ | q |
				  q.match( /^[a-z]+$/i ) ? $0 += " *#{q}* " : $0 += " #{q} "
			  }
		
				$0
			}

			@results = @pcs_projects.find_with_ferret( query, :limit => :all )
			@pcs_projects = @results

			# increase the search times for tags
			Tagcloud.increase_searched_tag( keyword ) if session[ :search_keyword ] != keyword
			session[ :search_keyword ] = keyword
		end

		# with nsc filter
    if params[ :nsc_or_not ] == 'true'
      @pcs_projects = @pcs_projects.find(:all, :order => sortable_order( 'listing')) 
      @pcs_projects = @pcs_projects.select{ |p| p.is_nsc_project }
    end

		# with paginate process
    @final_project_list = nil
    [ params[ :page ], 1 ].each do | page |
      @final_project_list = @pcs_projects.paginate(
		     :page => page,
		     :per_page => 10,
		     :include => [ :ready_releases ],
		     :order => sortable_order( 'listing', :model => Release, :field => 'updated_at', :sort_direction => :desc ) ) 

      break if not @final_project_list.out_of_bounds?
    end

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
