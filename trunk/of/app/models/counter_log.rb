class CounterLog < Ohm::Model
  reference :counter, Counter
  attribute :ip
  attribute :created_at
end
