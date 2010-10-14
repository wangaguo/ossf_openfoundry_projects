require 'rexml/document'
#xml_data = File.new("/tmp/svn.log").read
xml_data = STDIN.read
doc = REXML::Document.new(xml_data)

def getValue(element, path)
  result = ""
  element.elements.each(path) do |e|
    result += e.text
  end
  result
end


a2a = {} # author to action

ROOT = "http://svn.openfoundry.org/testproject04"
doc.elements.each('log/logentry') do |entry|
  #puts "____ #{entry} ____"
  revision = entry.attributes["revision"]
  #puts "revision: #{revision}"
  author = getValue(entry, "author")
  entry.elements.each("paths/path") do |path_element|
    action = path_element.attributes["action"]
    path = path_element.text
    info_revision = action != "D" ? revision : revision.to_i - 1

    # get node kind of the path
    cmd = "svn info -r#{info_revision} #{ROOT}#{path}@#{info_revision}"
    #puts "cmd: #{cmd}"
    result = %x[#{cmd}]
    result =~ /Node Kind: (\w+)/
    kind = $1
    
    (a2a[author] ||= {})["#{action} #{kind}"] ||= 0
    a2a[author]["#{action} #{kind}"] += 1
  end
end

require "pp"

#tmp = File.open("/tmp/a2a.txt", "w")
#tmp.print a2a.pretty_inspect
#tmp.close

id2name = {}
File.open("/tmp/mapping.txt").each do |line|
  #puts "line: #{line}"
  values = line.split
  if values[1] !~ /^[uU]/
    values[1] = "u" + values[1]
  end
  values[1].downcase!
  id2name[values[0]] = "#{values[1]} #{values[2]}"
end

#a2a = eval File.open("/tmp/a2a.txt").read
actions = a2a.values.map {|x| x.keys}.flatten.uniq.sort
body = ""
a2a.keys.select {|x| id2name[x] }.sort {|x, y| id2name[x] <=> id2name[y] }.each do |author|
  h = a2a[author]
  body += "<tr><td>#{id2name[author]} #{author}</td>   #{ actions.map {|act| "<td>#{ h[act] || '&nbsp;'  }</td>"   }    }</tr>\n"
end
puts "<table border='1'><tr><td>author</td>#{ actions.map{|a| "<th>#{a}</th>"} }</tr>#{body}</table>"
