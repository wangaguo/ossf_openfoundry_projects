xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @property[:title]
    xml.description @property[:description]

    for post in @rssdata
      xml.item do
        xml.title(post.title)
        xml.description(post.description)
        xml.pubDate(post.date.to_s(:rfc822))
        xml.link(post.link)
        xml.guid(post.link)
      end
    end
  end
end

