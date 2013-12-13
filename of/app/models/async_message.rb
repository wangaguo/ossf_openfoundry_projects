class AsyncMessage < ActiveRecord::Base
  belongs_to :async, :polymorphic => true

  def self.set_async(async)
    if async.async_message.nil?
      async.create_async_message(:params => "1")
    else
      async.async_message.params = "1"
      async.async_message.touch
      async.async_message.save
    end 
  end
end
