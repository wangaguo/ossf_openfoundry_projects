atom_feed do |feed|
  feed.title @property[:title]
  feed.subtitle @property[:description]

  for post in @rssdata
    feed.entry(post, {:updated => post.date, :url => post.link}) do |entry|
      entry.title(post.title)
      entry.content(post.description, :type => 'html')
    end
  end
end
