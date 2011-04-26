class CounterLogFlusher < ActionController::Metal
  def index
    ArchivedCounterLog.transaction do
      CounterLog.all.each do |cl|
        if cl.counter.item.is_a? Fileentity
          f = cl.counter.item
          ArchivedCounterLog.create(:project_id => f.release.project.id,
                                    :release_id => f.release.id,
                                    :file_entity_id => f.id,
                                    :ip => cl.ip,
                                    :created_at => Time.at(cl.created_at.to_i))
        end
        cl.delete
      end
    end
  end
end
