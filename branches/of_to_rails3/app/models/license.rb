class License < ActiveRecord::Base
  has_and_belongs_to_many :projects, :join_table => :projects_licenses
  scope :code, :conditions => 'domain like "%code%"'
  scope :content, :conditions => 'domain like "%content%"'

  def to_s
    "#{name}"
  end

end
