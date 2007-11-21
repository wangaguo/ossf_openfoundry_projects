class Admin::NewsController < AdminController 
  active_scaffold :News do |config|
    config.columns = [:subject, :descr, :tags, :catid]
    columns[:subject].label = "標題"
    columns[:descr].label = "內容"
    columns[:tags].label = "標籤"
    columns[:catid].label = "專案代碼"
  end
end
