class License < ActiveRecord::Base
  has_and_belongs_to_many :projects, :join_table => :projects_licenses
  named_scope :code, :conditions => 'domain like "%code%"'
  named_scope :content, :conditions => 'domain like "%content%"'

  def to_s
    "#{name}"
  end

end
