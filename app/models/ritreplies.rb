class Ritreplies < ActiveRecord::Base

  validates :title, 
            :presence => {:message => I18n.t('rit_add_validates_title_error')}
  
  validates :content, 
            :presence => {:message => I18n.t('rit_validates_content_error')}
  
  validates :guestmail,
            :presence => {:message => I18n.t('rit_validates_email_empty')},
            :format => {:with => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i,
                        :message => I18n.t('rit_validates_email_error', :mail => "%{value}" )}

  #belongs_to :rit
  #has_many :users
  REPLYTYPE = {:Reply => 0,:ChangeLog => 1, :Comment => 2, :ReplyOfComment => 3}.freeze
end
