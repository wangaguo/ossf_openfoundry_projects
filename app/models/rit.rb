class Rit < ActiveRecord::Base
  validates :title, 
            :presence => { :message => I18n.t('rit_add_validates_title_error')}
  
  validates :content, 
            :presence => { :message => I18n.t('rit_validates_content_error')}
  
  validates :guestmail,
            :presence => { :message => I18n.t('rit_validates_email_empty')},
            :format => { :with => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i,
                         :message => I18n.t('rit_validates_email_error', :mail => "%{value}" )}

  validates :status,
            :presence => { :message => 'do not hack the number' },
            :numericality => {  :in => 1..5 ,
                                :message => "do not hack the number" }
  validates :priority,
            :presence => { :message => 'do not hack the number' },
            :numericality => {  :in => 1..4 ,
                                :message => "do not hack the number" }
  validates :tickettype,
            :presence => { :message => 'do not hack the number' },
            :numericality => {  :in => 1..5 ,
                                :message => "do not hack the number" }

  STATUS = { :DELETE => 5, :OPEN => 1, :PROCESS => 2, :SUSPENDED => 3, :FINISH => 4 }.freeze
  PRIORITY = { :Urgent => 1, :High => 2, :Medium =>3 , :Low => 4 }.freeze
  TICKETTYPE = {:BUG => 1, :Patch => 2, :Task => 3, :Feature => 4, :Enhancement => 5 }.freeze
  
end
