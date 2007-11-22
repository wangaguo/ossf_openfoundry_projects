class Admin::NewsController < Admin
  active_scaffold :News do |config|
    config.show.link.label = '檢視'
    config.update.link.label = '編輯'
    config.delete.link.label = '刪除'
    config.label = 'OpenFoundry 新聞'
    
    config.columns = [:subject, :descr, :tags, :catid]
    columns[:subject].label = "標題"
    columns[:descr].label = "內容"
    columns[:tags].label = "標籤"
    columns[:catid].label = "專案代碼"
  end

  def project 
    @id = params[:id]
  end
end
