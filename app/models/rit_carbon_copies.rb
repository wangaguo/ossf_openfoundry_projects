class RitCarbonCopies < ActiveRecord::Base
  validates :email,
            :format => {:with => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i,
                        :message => I18n.t('rit_validates_email_error' , :mail => "%{value}" )}


end
