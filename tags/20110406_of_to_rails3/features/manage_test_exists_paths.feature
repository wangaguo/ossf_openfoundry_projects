Feature: Manage test_exists_paths
  In order to Test every exists Paths
  Our boss
  wants Test...
  
  Scenario: Test every exists paths
    When I go to the main page
      Then I should not be on the not_found page
    When I go to the /                                                                   
      Then I should not be on the not_found page
    When I go to the /category                                                 
      Then I should not be on the not_found page
    When I go to the /category/1                                             
      Then I should not be on the not_found page
    When I go to the /category/1/edit                                        
      Then I should not be on the not_found page
    When I go to the /category/new                                             
      Then I should not be on the not_found page
    When I go to the /fckeditor/check_spelling                                           
      Then I should not be on the not_found page
    When I go to the /fckeditor/command                                                  
      Then I should not be on the not_found page
    When I go to the /fckeditor/upload                                                   
      Then I should not be on the not_found page
    When I go to the /news                                                     
      Then I should not be on the not_found page
    When I go to the /news/1                                                 
      Then I should not be on the not_found page
    When I go to the /news/1/edit                                            
      Then I should not be on the not_found page
    When I go to the /news/new                                                 
      Then I should not be on the not_found page
    When I go to the /news/new_openfoundry_news_feed                           
      Then I should not be on the not_found page
    When I go to the /news/new_project_news_feed                               
      Then I should not be on the not_found page
    When I go to the /projects                                                 
      Then I should not be on the not_found page
    When I go to the /projects/1                                             
      Then I should not be on the not_found page
    When I go to the /projects/1/citations                           
      Then I should not be on the not_found page
    When I go to the /projects/1/citations/1                       
      Then I should not be on the not_found page
    When I go to the /projects/1/citations/1/edit                  
      Then I should not be on the not_found page
    When I go to the /projects/1/citations/new                       
      Then I should not be on the not_found page
    When I go to the /projects/1/download                                      
      Then I should not be on the not_found page
    When I go to the /projects/1/edit                                        
      Then I should not be on the not_found page
    When I go to the /projects/1/jobs                                
      Then I should not be on the not_found page
    When I go to the /projects/1/jobs/1                            
      Then I should not be on the not_found page
    When I go to the /projects/1/jobs/1/edit                       
      Then I should not be on the not_found page
    When I go to the /projects/1/jobs/new                            
      Then I should not be on the not_found page
    When I go to the /projects/1/kwiki                               
      Then I should not be on the not_found page
    When I go to the /projects/1/kwiki/1                           
      Then I should not be on the not_found page
    When I go to the /projects/1/kwiki/1/edit                      
      Then I should not be on the not_found page
    When I go to the /projects/1/kwiki/new                           
      Then I should not be on the not_found page
    When I go to the /projects/1/member_add                                  
      Then I should not be on the not_found page
    When I go to the /projects/1/member_delete                               
      Then I should not be on the not_found page
    When I go to the /projects/1/member_edit                                 
      Then I should not be on the not_found page
    When I go to the /projects/1/news                                
      Then I should not be on the not_found page
    When I go to the /projects/1/news/1                            
      Then I should not be on the not_found page
    When I go to the /projects/1/news/1/edit                       
      Then I should not be on the not_found page
    When I go to the /projects/1/news/new                            
      Then I should not be on the not_found page
    When I go to the /projects/1/news/new_release                    
      Then I should not be on the not_found page
    When I go to the /projects/1/nsc/nscreports                      
      Then I should not be on the not_found page
    When I go to the /projects/1/nsc/nscreports/1                  
      Then I should not be on the not_found page
    When I go to the /projects/1/nsc/nscreports/1/edit             
      Then I should not be on the not_found page
    When I go to the /projects/1/nsc/nscreports/new                  
      Then I should not be on the not_found page
    When I go to the /projects/1/project_board                               
      Then I should not be on the not_found page
    When I go to the /projects/1/references                          
      Then I should not be on the not_found page
    When I go to the /projects/1/references/1                      
      Then I should not be on the not_found page
    When I go to the /projects/1/references/1/edit                 
      Then I should not be on the not_found page
    When I go to the /projects/1/references/new                      
      Then I should not be on the not_found page
    When I go to the /projects/1/releases                            
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1                        
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/addfiles               
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/delete                 
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/delete_files           
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/download               
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/edit                   
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/editfile               
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/editrelease            
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/reload                 
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/removefile             
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/updatefile             
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/updaterelease          
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/uploadfiles            
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/viewfile               
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/viewrelease            
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/1/web_upload             
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/download                   
      Then I should not be on the not_found page
    When I go to the /projects/1/releases/new                        
      Then I should not be on the not_found page
    When I go to the /projects/1/reviews                                               
      Then I should not be on the not_found page
    When I go to the /projects/1/role_create                                 
      Then I should not be on the not_found page
    When I go to the /projects/1/role_new                                    
      Then I should not be on the not_found page
    When I go to the /projects/1/role_update                                 
      Then I should not be on the not_found page
    When I go to the /projects/1/role_users                                  
      Then I should not be on the not_found page
    When I go to the /projects/1/rt                                  
      Then I should not be on the not_found page
    When I go to the /projects/1/rt/1                              
      Then I should not be on the not_found page
    When I go to the /projects/1/rt/1/edit                         
      Then I should not be on the not_found page
    When I go to the /projects/1/rt/new                              
      Then I should not be on the not_found page
    When I go to the /projects/1/survey                              
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/1                          
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/1/apply                    
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/1/delete                   
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/1/edit                     
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/1/update                   
      Then I should not be on the not_found page
    When I go to the /projects/1/survey/new                          
      Then I should not be on the not_found page
    When I go to the /projects/1/sympa                                       
      Then I should not be on the not_found page
    When I go to the /projects/1/test_action                                 
      Then I should not be on the not_found page
    When I go to the /projects/1/vcs_access                                  
      Then I should not be on the not_found page
    When I go to the /projects/1/viewvc                                      
      Then I should not be on the not_found page
    When I go to the /projects/1/websvn                                      
      Then I should not be on the not_found page
    When I go to the /projects/applied                                         
      Then I should not be on the not_found page
    When I go to the /projects/jobs                                                      
      Then I should not be on the not_found page
    When I go to the /projects/list                                            
      Then I should not be on the not_found page
    When I go to the /projects/new                                             
      Then I should not be on the not_found page
    When I go to the /projects/news                                                      
      Then I should not be on the not_found page
    When I go to the /projects/news_projects_feed                              
      Then I should not be on the not_found page
    When I go to the /projects/project_board                                   
      Then I should not be on the not_found page
    When I go to the /projects/tableizer                                       
      Then I should not be on the not_found page
    When I go to the /projects/test_action                                     
      Then I should not be on the not_found page
    When I go to the /rt                                                       
      Then I should not be on the not_found page
    When I go to the /rt/1                                                   
      Then I should not be on the not_found page
    When I go to the /rt/1/edit                                              
      Then I should not be on the not_found page
    When I go to the /rt/new                                                   
      Then I should not be on the not_found page
    When I go to the /site_admin 
      Then I should not be on the not_found page
    When I go to the /user/dashboard
      Then I should not be on the not_found page
