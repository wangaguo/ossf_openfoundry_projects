class CounterLogFlusher < ActionController::Metal
  def index
    if params[:limit] 
      if params[:limit].to_i <= 5000
        limit = params[:limit].to_i
      else
        limit = 5000
      end
    else  
      limit = 1000
    end

    logs = CounterLog.all.take(limit)
    bulk_data = []
    logs.each do |cl|
      bulk_data << ArchivedCounterLog.new(:project_id => cl.project_id,
                                  :release_id => cl.release_id,
                                  :file_entity_id => cl.file_id,
                                  :ip => cl.ip,
                                  :created_at => Time.at(cl.created_at.to_i))
    end

    ArchivedCounterLog.transaction do
      ArchivedCounterLog.import(bulk_data)
      logs.each do |cl|
        cl.delete
      end
    end
  end
end

