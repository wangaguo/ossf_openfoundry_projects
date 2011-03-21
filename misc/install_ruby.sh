#!/bin/sh
: ${myprefix=$HOME/ruby}
: ${download_dir=$myprefix/download}
: ${build_dir=$myprefix/build}
: ${ruby_dir=$myprefix/ruby}

: ${libiconv_url=http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.12.tar.gz}
: ${ruby_url=ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.6-p114.tar.gz}
: ${rubygems_url=http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz}
: ${ruby_make_target=install-all}


install_iconv_freebsd()
{
	download "$libiconv_url"
	mkdir -p "$build_dir" 
	cd "$build_dir"
	base_name=${libiconv_url##*/}
	tar zxpf "$download_dir/$base_name"
	base_name=${base_name%.tar.gz}
	cd "$base_name"
	./configure "--prefix=$myprefix/$base_name"
	make install
}

# $1: url
download()
{
	url=$1

	mkdir -p "$download_dir"
	base_name=${url##*/}
	output_file="$download_dir/$base_name"
        if [ ! -f $output_file ]; then
		echo "downloading $url to $download_dir ..."
		if [ 'FreeBSD' = `uname` ]; then
			fetch -o "${output_file}" "$url"
		else
			wget -O "${output_file}" "$url"
		fi
        fi
}

install_prerequisites()
{
	if [ 'FreeBSD' = `uname` ]; then
		echo 'installing prerequisites for FreeBSD ...'
		install_iconv_freebsd
	else
		echo 'installing prerequisites for Ubuntu ...'
		sudo apt-get install build-essential zlib1g-dev libreadline-dev libssl-dev
	fi
}

extract_and_make_ruby()
{
	cd "$build_dir"
	base_name=${ruby_url##*/}
	tar zxpf "$download_dir/$base_name"
	base_name=${base_name%.tar.gz}
	cd "$base_name"
	./configure --prefix "$ruby_dir"
	make
	make "$ruby_make_target"
}


extract_and_make_rubygems()
{
	cd "$build_dir"
	base_name=${rubygems_url##*/}
	tar zxpf "$download_dir/$base_name"
	base_name=${base_name%.tgz}
	cd "$base_name"
	touch "$build_dir/before_install_rubygems"; sleep 1
	ruby setup.rb
	find "$ruby_dir" -newer "$build_dir/before_install_rubygems" > "$build_dir"/after_install_rubygems
}

install_prerequisites
download "$ruby_url"
extract_and_make_ruby $download $build $ruby

PATH="$ruby_dir/bin:$PATH"; export PATH
download "$rubygems_url"
extract_and_make_rubygems

echo "Please add the following settings:"
echo "PATH=\"$ruby_dir/bin:\$PATH\"; export PATH" | tee "$myprefix/ruby_settings.sh"
echo "or"
echo "setenv PATH \"$ruby_dir/bin:\$PATH\"" | tee "$myprefix/ruby_settings.csh"
