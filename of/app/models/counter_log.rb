class CounterLog < Ohm::Model
  attribute :project_id
  attribute :release_id
  attribute :file_id
  attribute :ip
  attribute :user_agent
  attribute :created_at

  index :project_id
  index :release_id
  index :file_id
end
