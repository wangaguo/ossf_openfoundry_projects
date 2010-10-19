class Citation < ActiveRecord::Base
  belongs_to :project, :foreign_key => "project_id"
  STATUS = {:Enabled => 1, :Disabled => 0}

  validates_length_of :primary_authors, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :project_title, :within => 3..255, :too_long => _("Length range is ") + "3-255", :too_short => _("Length range is ") + "3-255"
  validates_length_of :license, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :url, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_length_of :release_version, :within => 0..255, :too_long => _("Length range is ") + "0-255", :too_short => _("Length range is ") + "0-255"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  
  def validate
    if !release_date.nil?
      date_pattern = /^(19|20)\d\d[- \/.](0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])$/
      errors.add(:release_date, "must be formatted YYYY-MM-DD or YYYY/MM/DD") if
      date_pattern !~ release_date_before_type_cast
    end
  end
end