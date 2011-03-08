module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    
    when /the home\s?page/
      '/'
    when /the main page/
      root_path 
    when /the not_found page/
      not_found_rescue_path 
    when /the new test_exists_paths page/
      new_test_exists_paths_path
    when /not_exists page/
      'http://ssodev.openfoundry.org/of/ggggggg'
when /\// 
 "/"
when /\/category/ 
 "/category"
when /\/category\/1/ 
 "/category/1"
when /\/category\/1\/edit/ 
 "/category/1/edit"
when /\/category\/new/ 
 "/category/new"
when /\/fckeditor\/check_spelling/ 
 "/fckeditor/check_spelling"
when /\/fckeditor\/command/ 
 "/fckeditor/command"
when /\/fckeditor\/upload/ 
 "/fckeditor/upload"
when /\/news/ 
 "/news"
when /\/news\/1/ 
 "/news/1"
when /\/news\/1\/edit/ 
 "/news/1/edit"
when /\/news\/new/ 
 "/news/new"
when /\/news\/new_openfoundry_news_feed/ 
 "/news/new_openfoundry_news_feed"
when /\/news\/new_project_news_feed/ 
 "/news/new_project_news_feed"
when /\/projects/ 
 "/projects"
when /\/projects\/1/ 
 "/projects/1"
when /\/projects\/1\/citations/ 
 "/projects/1/citations"
when /\/projects\/1\/citations\/1/ 
 "/projects/1/citations/1"
when /\/projects\/1\/citations\/1\/edit/ 
 "/projects/1/citations/1/edit"
when /\/projects\/1\/citations\/new/ 
 "/projects/1/citations/new"
when /\/projects\/1\/download/ 
 "/projects/1/download"
when /\/projects\/1\/edit/ 
 "/projects/1/edit"
when /\/projects\/1\/jobs/ 
 "/projects/1/jobs"
when /\/projects\/1\/jobs\/1/ 
 "/projects/1/jobs/1"
when /\/projects\/1\/jobs\/1\/edit/ 
 "/projects/1/jobs/1/edit"
when /\/projects\/1\/jobs\/new/ 
 "/projects/1/jobs/new"
when /\/projects\/1\/kwiki/ 
 "/projects/1/kwiki"
when /\/projects\/1\/kwiki\/1/ 
 "/projects/1/kwiki/1"
when /\/projects\/1\/kwiki\/1\/edit/ 
 "/projects/1/kwiki/1/edit"
when /\/projects\/1\/kwiki\/new/ 
 "/projects/1/kwiki/new"
when /\/projects\/1\/member_add/ 
 "/projects/1/member_add"
when /\/projects\/1\/member_delete/ 
 "/projects/1/member_delete"
when /\/projects\/1\/member_edit/ 
 "/projects/1/member_edit"
when /\/projects\/1\/news/ 
 "/projects/1/news"
when /\/projects\/1\/news\/1/ 
 "/projects/1/news/1"
when /\/projects\/1\/news\/1\/edit/ 
 "/projects/1/news/1/edit"
when /\/projects\/1\/news\/new/ 
 "/projects/1/news/new"
when /\/projects\/1\/news\/new_release/ 
 "/projects/1/news/new_release"
when /\/projects\/1\/nsc\/nscreports/ 
 "/projects/1/nsc/nscreports"
when /\/projects\/1\/nsc\/nscreports\/1/ 
 "/projects/1/nsc/nscreports/1"
when /\/projects\/1\/nsc\/nscreports\/1\/edit/ 
 "/projects/1/nsc/nscreports/1/edit"
when /\/projects\/1\/nsc\/nscreports\/new/ 
 "/projects/1/nsc/nscreports/new"
when /\/projects\/1\/project_board/ 
 "/projects/1/project_board"
when /\/projects\/1\/references/ 
 "/projects/1/references"
when /\/projects\/1\/references\/1/ 
 "/projects/1/references/1"
when /\/projects\/1\/references\/1\/edit/ 
 "/projects/1/references/1/edit"
when /\/projects\/1\/references\/new/ 
 "/projects/1/references/new"
when /\/projects\/1\/releases/ 
 "/projects/1/releases"
when /\/projects\/1\/releases\/1/ 
 "/projects/1/releases/1"
when /\/projects\/1\/releases\/1\/addfiles/ 
 "/projects/1/releases/1/addfiles"
when /\/projects\/1\/releases\/1\/delete/ 
 "/projects/1/releases/1/delete"
when /\/projects\/1\/releases\/1\/delete_files/ 
 "/projects/1/releases/1/delete_files"
when /\/projects\/1\/releases\/1\/download/ 
 "/projects/1/releases/1/download"
when /\/projects\/1\/releases\/1\/edit/ 
 "/projects/1/releases/1/edit"
when /\/projects\/1\/releases\/1\/editfile/ 
 "/projects/1/releases/1/editfile"
when /\/projects\/1\/releases\/1\/editrelease/ 
 "/projects/1/releases/1/editrelease"
when /\/projects\/1\/releases\/1\/reload/ 
 "/projects/1/releases/1/reload"
when /\/projects\/1\/releases\/1\/removefile/ 
 "/projects/1/releases/1/removefile"
when /\/projects\/1\/releases\/1\/updatefile/ 
 "/projects/1/releases/1/updatefile"
when /\/projects\/1\/releases\/1\/updaterelease/ 
 "/projects/1/releases/1/updaterelease"
when /\/projects\/1\/releases\/1\/uploadfiles/ 
 "/projects/1/releases/1/uploadfiles"
when /\/projects\/1\/releases\/1\/viewfile/ 
 "/projects/1/releases/1/viewfile"
when /\/projects\/1\/releases\/1\/viewrelease/ 
 "/projects/1/releases/1/viewrelease"
when /\/projects\/1\/releases\/1\/web_upload/ 
 "/projects/1/releases/1/web_upload"
when /\/projects\/1\/releases\/download/ 
 "/projects/1/releases/download"
when /\/projects\/1\/releases\/new/ 
 "/projects/1/releases/new"
when /\/projects\/1\/reviews/ 
 "/projects/1/reviews"
when /\/projects\/1\/role_create/ 
 "/projects/1/role_create"
when /\/projects\/1\/role_new/ 
 "/projects/1/role_new"
when /\/projects\/1\/role_update/ 
 "/projects/1/role_update"
when /\/projects\/1\/role_users/ 
 "/projects/1/role_users"
when /\/projects\/1\/rt/ 
 "/projects/1/rt"
when /\/projects\/1\/rt\/1/ 
 "/projects/1/rt/1"
when /\/projects\/1\/rt\/1\/edit/ 
 "/projects/1/rt/1/edit"
when /\/projects\/1\/rt\/new/ 
 "/projects/1/rt/new"
when /\/projects\/1\/survey/ 
 "/projects/1/survey"
when /\/projects\/1\/survey\/1/ 
 "/projects/1/survey/1"
when /\/projects\/1\/survey\/1\/apply/ 
 "/projects/1/survey/1/apply"
when /\/projects\/1\/survey\/1\/delete/ 
 "/projects/1/survey/1/delete"
when /\/projects\/1\/survey\/1\/edit/ 
 "/projects/1/survey/1/edit"
when /\/projects\/1\/survey\/1\/update/ 
 "/projects/1/survey/1/update"
when /\/projects\/1\/survey\/new/ 
 "/projects/1/survey/new"
when /\/projects\/1\/sympa/ 
 "/projects/1/sympa"
when /\/projects\/1\/test_action/ 
 "/projects/1/test_action"
when /\/projects\/1\/vcs_access/ 
 "/projects/1/vcs_access"
when /\/projects\/1\/viewvc/ 
 "/projects/1/viewvc"
when /\/projects\/1\/websvn/ 
 "/projects/1/websvn"
when /\/projects\/applied/ 
 "/projects/applied"
when /\/projects\/jobs/ 
 "/projects/jobs"
when /\/projects\/list/ 
 "/projects/list"
when /\/projects\/new/ 
 "/projects/new"
when /\/projects\/news/ 
 "/projects/news"
when /\/projects\/news_projects_feed/ 
 "/projects/news_projects_feed"
when /\/projects\/project_board/ 
 "/projects/project_board"
when /\/projects\/tableizer/ 
 "/projects/tableizer"
when /\/projects\/test_action/ 
 "/projects/test_action"
when /\/rt/ 
 "/rt"
when /\/rt\/1/ 
 "/rt/1"
when /\/rt\/1\/edit/ 
 "/rt/1/edit"
when /\/rt\/new/ 
 "/rt/new"
when /\/site_admin/ 
 "/site_admin"
when /\/user\/dashboard/
 "/user/dashboard"  
    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
