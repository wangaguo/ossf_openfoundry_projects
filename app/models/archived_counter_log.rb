class ArchivedCounterLog < ActiveRecord::Base
  belongs_to :project
  belongs_to :release
  belongs_to :file_entity, :class_name => 'Fileentity'
end
