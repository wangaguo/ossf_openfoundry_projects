class Rit < ActiveRecord::Base
  validates_presence_of :title, :content
  validates_presence_of :guestmail
  validates_format_of :guestmail, :with => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  STATUS = { :DELETE => 0, :OPEN => 1, :PROCESS => 2, :SUSPENDED => 3, :FINISH => 4 }.freeze
  PRIORITY = { :Urgent => 0, :High => 1, :Medium =>2 , :Low => 3 }.freeze
  TICKETTYPE = {:BUG => 0, :Patch => 1, :Task => 2, :Feature => 3, :Enhancement => 4 }.freeze
  
  def translated_priority
    I18n.t(name, :scope => 'ritstatus')
  end

end
