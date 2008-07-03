class Job < ActiveRecord::Base
  STATUS = {:Enabled => 1, :Disabled => 0}

  validates_length_of :subject, :within => 3..255, :too_long => _("Length range is ") + "3-255", :too_short => _("Length range is ") + "3-255"
  validates_length_of :description, :within => 3..4000, :too_long => _("Length range is ") + "3-4000", :too_short => _("Length range is ") + "3-4000"
  validates_inclusion_of :status, :in => STATUS.values, :message => _("Not a valid value")
  
  def validate
    date_pattern = /^(19|20)\d\d[- \/.](0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])$/
    errors.add(:due, "must be formatted YYYY-MM-DD or YYYY/MM/DD") if
    due.nil? || date_pattern !~ due_before_type_cast
  end
  
end
