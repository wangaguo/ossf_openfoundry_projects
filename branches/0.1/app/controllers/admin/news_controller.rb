class Admin::NewsController < Admin
  active_scaffold :News do |config|
    config.show.link.label = '檢視'
    config.update.link.label = '編輯'
    config.delete.link.label = '刪除'
    config.label = 'OpenFoundry 新聞'
    
    config.list.columns = [:subject, :description, :tags, :catid, :created_at, :updated_at]
    config.columns = [:subject, :description, :tags, :catid, :created_at, :updated_at]
    config.create.columns = [:subject, :description, :tags, :catid]
    config.update.columns = [:subject, :description, :tags, :catid]
    
    columns[:subject].label = "標題"
    columns[:description].label = "內容"
    #config.columns[:description].ui_type = :textarea # => {:cols => 50, :rows => 5}
    # config.update.columns[:description].form_ui = :password

    #config.columns[:tags].options = { :autocomplete => "off", :size => 50}
    # config.columns[:description].ui_type = :textarea
    #config.columns[:description].ui_type = [:textarea]
    columns[:tags].label = "標籤"
    columns[:catid].label = "專案"
    columns[:created_at].label = "建立日期"
    columns[:updated_at].label = "更新日期"
    
    columns[:catid].description = "輸入專案代號, 0為OpenFoundry新聞."
  end

  def project 
    @id = params[:id]
  end

end
