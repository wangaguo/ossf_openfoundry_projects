#!/bin/sh
myprefix=$HOME/ruby
sudo apt-get install build-essential zlib1g-dev libreadline-dev libssl-dev

mkdir -p $myprefix
mkdir -p $myprefix/download
cd $myprefix/download

wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p111.tar.gz
tar zxpf ruby-1.8.6-p111.tar.gz
cd ruby-1.8.6-p111
./configure --prefix "$myprefix/ruby"
make
make install-all
PATH="$myprefix/ruby/bin:$PATH"; export PATH
cd ..

wget http://rubyforge.org/frs/download.php/20989/rubygems-0.9.4.tgz
tar zxpf rubygems-0.9.4.tgz
cd rubygems-0.9.4
GEM_HOME="$myprefix/gem_home"; export GEM_HOME
ruby setup.rb config --prefix="$myprefix/gem_prefix"
#ruby setup.rb config
ruby setup.rb setup
ruby setup.rb install
cd ..


echo "Please add the following settings:"
echo "GEM_HOME=\"$myprefix/gem_home\"; export GEM_HOME"
echo "PATH=\"$myprefix/ruby/bin:$myprefix/gem_prefix/bin:$myprefix/gem_home/bin:\$PATH\"; export PATH"
#echo "PATH=\"$myprefix/ruby/bin:\$PATH\"; export PATH"
