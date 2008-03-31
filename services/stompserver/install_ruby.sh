#!/bin/sh
myprefix="%%InstallDir%%/ruby"
download="$myprefix/download"
build="$myprefix/build"
ruby="$myprefix/ruby"

# remember to fix this...
ruby_src="ruby-1.8.6.tar.gz"
ruby_src_dir="ruby-1.8.6"
ruby_src_site="ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6.tar.gz"
rubygems_src="rubygems-1.1.0.tgz"
rubygems_src_dir="rubygems-1.1.0"
rubygems_src_site="http://rubyforge.org/frs/download.php/34638/rubygems-1.1.0.tgz"

# download build
install_iconv_freebsd()
{
	olddir=`pwd`
	download $1 libiconv-1.12.tar.gz http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.12.tar.gz
	mkdir -p $2
	cd $2
	tar zxpf $1/libiconv-1.12.tar.gz
	cd libiconv-1.12
	./configure --prefix=$myprefix/libiconv-1.12
	make install
        cd $olddir
}

# download download_dir target_dir filename url
# no base name..
download()
{
        olddir=`pwd`
        mkdir -p $1
        cd $1
        if [ ! -f $2 ]; then
		echo "going to download $3"
		if [ 'FreeBSD' = `uname` ]; then
			fetch $3
		else
			wget $3
		fi
        fi
        cd $olddir
}


# download build
install_prerequisites()
{
	if [ 'FreeBSD' = `uname` ]; then
		echo 'installing prerequisites for FreeBSD ...'
		install_iconv_freebsd $1 $2
	else
		echo 'installing prerequisites for Ubuntu ...'
		sudo apt-get install build-essential zlib1g-dev libreadline-dev libssl-dev
	fi
}

# use absolute paths as parameters
# download build prefix
extract_and_make_ruby()
{
	olddir=`pwd`
	mkdir -p $2
	cd $2
	tar zxpf $1/$4
	cd $5
	./configure --prefix $3
	make
	make install-all
	cd $olddir
}


# use absolute paths as parameters
# download build prefix
extract_and_make_rubygems()
{
	olddir=`pwd`
	mkdir -p $2
	cd $2
	tar zxpf $1/$4
	cd $5
	touch $2/before_install_rubygems; sleep 1
	ruby setup.rb
	find $ruby -newer $2/before_install_rubygems > $2/after_install_rubygems
	cd $olddir
}

install_prerequisites $download $build
download $download $ruby_src $ruby_src_site
extract_and_make_ruby $download $build $ruby $ruby_src $ruby_src_dir
PATH="$ruby/bin:$PATH"; export PATH
download $download $rubygems_src $rubygems_src_site
extract_and_make_rubygems $download $build $ruby $rubygems_src $rubygems_src_dir

gem install stompserver 
echo "Please add the following settings:"
echo "PATH=\"$ruby/bin:\$PATH\"; export PATH"
echo "PATH=\"$ruby/bin:\$PATH\"; export PATH" > "$myprefix/ruby_settings.sh"
echo "or"
echo "setenv PATH \"$ruby/bin:\$PATH\""
echo "setenv PATH \"$ruby/bin:\$PATH\"" > "$myprefix/ruby_settings.csh"

