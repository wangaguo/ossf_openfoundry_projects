class Counter < Ohm::Model
  attribute :item_id
  attribute :item_class
  attribute :item_counter_attribute
  counter :counter
  attribute :flushed_at # should store time as integer
  collection :logs, CounterLog

  index :id
  index :item_id
  index :item_class

  def item
    @item ||= self.item_class.constantize.find(self.item_id)
  end

  alias :origin_counter :counter
  def counter
    self.flush
    self.origin_counter
  end

  def increase
    self.incr :counter
    self.flush
  end

  def flush
    # redis don't have real integer type, so i need to use to_i to convert it
    self.flush! if (self.flushed_at.to_i < Time.now.to_i - 300) &&
                   # don't update if value has not change
                   (self.origin_counter.to_i > item.send(item_counter_attribute))
  end

  def add_log(hash)
    counter_log = CounterLog.new(hash.merge(:counter_id => self.id, :created_at => Time.now.to_i))
    counter_log.save
    self.logs << counter_log
  end

  def flush!
    if self.item.nil?
      Rails.logger.warn("Counter#flush: #{self.item_class}##{self.item_id} does not exists.")
    else
      # FIXME: fix this when we find why after save causes fucking transaction lock
      ActiveRecord::Base.connection.execute "update #{item_class.downcase.pluralize} 
                                             set #{item_counter_attribute} = #{self.origin_counter} 
                                             where id = #{item_id}"
      self.flushed_at = Time.now.to_i
      self.save
    end
  end
end
