#!/bin/sh


# I apologize that this is designed only for Ubuntu

# Please feel free to help if you're interested in extending
# it for more Linux distributions


read -p "Do you wish to install Haxe and Neko? (y/n) " RESP

if [ $RESP = "y" ]; then
	
	
	echo ""
	echo "-----------------------------------"
	echo " Removing Haxe (if installed)"
	echo "-----------------------------------"

	sudo apt-get remove haxe

	
	if [ `uname -m` = "x86_64" ]; then
		
		
		echo ""
		echo "-----------------------------------"
		echo " Installing IA32 libraries"
		echo "-----------------------------------"	
	
		sudo apt-get install ia32-libs-multiarch gcc-multilib g++-multilib
		
		# The Haxe installer will download a 32-bit version of neko

		echo ""
		echo "-----------------------------------"
		echo " Downloading 64-bit Neko"
		echo "-----------------------------------"	
	
		wget http://www.haxenme.org/files/5613/3460/7773/neko-1.8.2-linux.tar.gz
		
		
	fi

	
	# The version of Haxe in the package manager is probably
	# out-of-date. Download the latest version from haxe.org
	
	echo ""
	echo "-----------------------------------"
	echo " Downloading the Haxe installer"
	echo "-----------------------------------"	
	
	wget http://haxe.org/file/hxinst-linux.tgz

	# Extract and run the Haxe installer, then clean up
	# afterwards

	tar xvzf hxinst-linux.tgz

	echo ""
	echo "-----------------------------------"
	echo " Running the Haxe installer"
	echo "-----------------------------------"	

	sudo ./hxinst-linux
	rm hxinst-linux
	rm hxinst-linux.tgz
	
	
	if [ `uname -m` = 'x86_64' ]; then
		
		# Need to recompile haxelib for 64-bit

		haxe /usr/lib/haxe/std/tools/haxelib/haxelib.hxml
		sudo cp haxelib /usr/lib/haxe/haxelib
		rm index.n
		rm haxelib.n
		rm haxelib
		
	fi
	
	# Setup haxelib
	
	sudo haxelib setup /usr/lib/haxe/lib

fi


echo ""
echo "-----------------------------------"
echo " Installing HXCPP and Jeash"
echo "-----------------------------------"

# Download dependencies using haxelib

#haxelib install hxcpp

#wget http://www.haxenme.org/files/1613/3237/4766/hxcpp-2.08.3.zip
#haxelib test hxcpp-2.08.3.zip
#rm hxcpp-2.08.3.zip

haxelib install hxcpp
haxelib install jeash


echo ""
echo "-----------------------------------"
echo " Installing NME 3.3.0"
echo "-----------------------------------"

# Download and install NME

haxelib install nme

# Add "nme" command shortcut

sudo haxelib run nme setup


echo ""
echo "-----------------------------------"
echo " Installing additional libraries"
echo "-----------------------------------"

haxelib install actuate
haxelib install swf


echo ""


