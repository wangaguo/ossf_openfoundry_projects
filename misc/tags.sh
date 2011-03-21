#!/bin/sh
mkdir ~/tags
ctags -f ~/tags/ruby_c -V -R --languages=-Ruby ~/ruby/download/ruby-1*
rtags -f ~/tags/ruby_ruby --vi -R  ~/ruby/ruby
rtags -f ~/tags/ruby_gems --vi -R  ~/ruby/gem_home
rtags -f ~/tags/0.1 --vi -R  ~/checkout/branches/0.1



