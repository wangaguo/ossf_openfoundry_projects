ActsAsFerret::define_index('shared',
 :models => {
   User  => { 
                              :login => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :untokenized },
                              :firstname => { :store => :yes,
                                              :index => :untokenized },
                              :lastname => { :store => :yes,
                                             :index => :untokenized },
                              :name => { :boost => 1.5,
                                         :store => :yes,
                                         :index => :untokenized }             
                            },
   Project => { 
                              :name => { :boost => 1.5,
                                         :store => :yes,
                                         :index => :untokenized },
                              :summary => { :store => :yes,
                                            :index => :yes },                           
                              :description => { :store => :yes,
                                                :index => :yes }                                                         
                            },
   News    => { 
                              :subject => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :yes },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
   Release => { 
                              :name => { :boost => 1.5,
                                          :store => :yes,
                                          :index => :untokenized },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
   Fileentity => { 
                              :name => { :boost => 1.5,
                                          :store => :no,
                                          :index => :untokenized },
                              :description => { :store => :no,
                                             :index => :yes }                                                         
                            }                            
 },
 :ferret   => {
   :default_fields => [:login, :first_name, :last_name, :name, :description]
 }
)
