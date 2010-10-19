class Reference < ActiveRecord::Base
  belongs_to :project, :foreign_key => "project_id"
  STATUS = {:Enabled => 1, :Disabled => 0}

  validates_length_of :source, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
end
