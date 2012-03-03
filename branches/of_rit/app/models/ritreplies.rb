class Ritreplies < ActiveRecord::Base

  validates_presence_of :title, :content, :guestmail

  validates_format_of :guestmail, :with => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i

  #belongs_to :rit
  #has_many :users
  REPLYTYPE = {:Reply => 0,:ChangeLog => 1, :Comment => 2, :ReplyOfComment => 3}.freeze
end
