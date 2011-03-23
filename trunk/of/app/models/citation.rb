class Citation < ActiveRecord::Base
  belongs_to :project, :foreign_key => "project_id"
  STATUS = {:Enabled => 1, :Disabled => 0}

  validates_length_of :primary_authors, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :project_title, :within => 3..255, :too_long => _("Length range is ") + "3-255", :too_short => _("Length range is ") + "3-255"
  validates_length_of :license, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :url, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :release_version, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  validates_exclusion_of :release_date, :in => [nil], :message => _("is an invalid datetime")
end
