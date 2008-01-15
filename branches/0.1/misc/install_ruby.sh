#!/bin/sh
myprefix="$HOME/ruby"
download="$myprefix/download"
build="$myprefix/build"
ruby="$myprefix/ruby"

install_prerequisites()
{
	sudo apt-get install build-essential zlib1g-dev libreadline-dev libssl-dev
}

download_ruby()
{
	olddir=`pwd`
	mkdir -p $1
	cd $1
	if [ ! -f ruby-1.8.6-p111.tar.gz ]; then
		#wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p111.tar.gz
		wget http://ftp.cs.pu.edu.tw/Unix/lang/Ruby/ruby-1.8.6-p111.tar.gz
	fi
	cd $olddir
}

# use absolute paths as parameters
# download build prefix
extract_and_make_ruby()
{
	olddir=`pwd`
	mkdir -p $2
	cd $2
	tar zxpf $1/ruby-1.8.6-p111.tar.gz
	cd ruby-1.8.6-p111
	./configure --prefix $3
	make
	make install-all
	cd $olddir
}


download_rubygems()
{
	olddir=`pwd`
	mkdir -p $1
	cd $1
	if [ ! -f rubygems-1.0.1.tgz ]; then
		wget http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz
	fi
	cd $olddir
}

# use absolute paths as parameters
# download build prefix
extract_and_make_rubygems()
{
	olddir=`pwd`
	mkdir -p $2
	cd $2
	tar zxpf $1/rubygems-1.0.1.tgz
	cd rubygems-1.0.1
	touch $2/before_install_rubygems; sleep 1
	ruby setup.rb
	find $ruby -newer $2/before_install_rubygems > $2/after_install_rubygems
	cd $olddir
}

install_prerequisites
download_ruby $download
extract_and_make_ruby $download $build $ruby
PATH="$ruby/bin:$PATH"; export PATH
#ruby -v
download_rubygems $download
extract_and_make_rubygems $download $build $ruby

echo "Please add the following settings:"
echo "PATH=\"$ruby/bin:\$PATH\"; export PATH"
echo "PATH=\"$ruby/bin:\$PATH\"; export PATH" > "$myprefix/ruby_settings"

