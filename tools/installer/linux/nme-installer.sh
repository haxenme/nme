#!/bin/sh


# I apologize in advance that this is configured for Ubuntu
# We will add better support for other distributions in the future


read -p "Do you wish to install Haxe and Neko? (y/n) " RESP

if [ $RESP = "y" ]; then
	
	
	sudo apt-get remove haxe
	

	# If you are running 64-bit, you'll need 32-bit support
	
	echo "-----------------------------------"
	echo " Installing IA32 libraries"
	echo "-----------------------------------"	
	
	sudo apt-get install ia32-libs-multiarch gcc-multilib g++-multilib
	
	
	# The version of Haxe in the package manager is probably
	# out-of-date. Download the latest version from haxe.org
	
	echo "-----------------------------------"
	echo " Downloading the Haxe installer"
	echo "-----------------------------------"	
	
	wget http://haxe.org/file/hxinst-linux.tgz

	# Extract and run the Haxe installer, then clean up
	# afterwards

	tar xvzf hxinst-linux.tgz

	echo "-----------------------------------"
	echo " Running the Haxe installer"
	echo "-----------------------------------"	

	sudo ./hxinst-linux
	rm hxinst-linux
	rm hxinst-linux.tgz

	# The installed version of Neko is 32-bit, and we may be on
	# a 64-bit system, so we'll re-install it using the package
	# manager

	
	echo "-----------------------------------"
	echo " Re-installing Neko (64-bit support)"
	echo "-----------------------------------"
	
	sudo apt-get remove neko
	sudo apt-get install neko

	# Need to recompile haxelib 

	haxe /usr/lib/haxe/std/tools/haxelib/haxelib.hxml
	sudo cp haxelib.n /usr/lib/haxe/haxelib.n
	rm index.n
	rm haxelib
	rm haxelib.n
	sudo nekotools boot /usr/lib/haxe/haxelib.n

	# Setup haxelib
	
	sudo haxelib setup /usr/lib/haxe/lib

fi


echo "-----------------------------------"
echo " Installing HXCPP and Jeash"
echo "-----------------------------------"

# Download dependencies using haxelib

#haxelib install hxcpp

wget http://www.haxenme.org/files/1613/3237/4766/hxcpp-2.08.3.zip
haxelib test hxcpp-2.08.3.zip
rm hxcpp-2.08.3.zip

haxelib install jeash


echo "-----------------------------------"
echo " Installing NME 3.3.0"
echo "-----------------------------------"

# Download and install NME

haxelib install nme

# Add "nme" command shortcut

sudo haxelib run nme setup


echo "-----------------------------------"
echo " Installing additional libraries"
echo "-----------------------------------"

haxelib install actuate
haxelib install swf

