class News < ActiveRecord::Base
  def self.home_news
    news = News.find(:all, :conditions=>['catid="0"'])
  end
end
