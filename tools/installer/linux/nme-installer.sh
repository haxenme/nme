#!/bin/sh


read -p "Do you wish to install Haxe 2.10 and Neko 1.8.2? (y/n) " RESP

if [ $RESP = "y" ]; then
	
	
	echo ""
	echo "-----------------------------------"
	echo "    Removing Haxe (if installed)"
	echo "-----------------------------------"

	sudo apt-get remove haxe neko
	
	
	if [ `uname -m` = "x86_64" ]; then
		
		
		echo ""
		echo "-----------------------------------"
		echo "    Downloading Neko (64-bit)"
		echo "-----------------------------------"	
	
		wget -c http://www.nme.io/builds/neko-1.8.2-linux64.tar.gz
		
		
		echo ""
		echo "-----------------------------------"
		echo "    Installing Neko"
		echo "-----------------------------------"
		
		# Extract and copy files to /usr/lib/neko
		
		tar xvzf neko-1.8.2-linux64.tar.gz
		sudo mkdir -p /usr/lib/neko
		sudo cp -r neko-1.8.2-linux64/* /usr/lib/neko
		
		# Add symlinks
		
		sudo rm -rf /usr/bin/neko
		sudo rm -rf /usr/bin/nekoc
		sudo rm -rf /usr/bin/nekotools
		sudo rm -rf /usr/lib/libneko.so
		
		sudo ln -s /usr/lib/neko/neko /usr/bin/neko
		sudo ln -s /usr/lib/neko/nekoc /usr/bin/nekoc
		sudo ln -s /usr/lib/neko/nekotools /usr/bin/nekotools
		sudo ln -s /usr/lib/neko/libneko.so /usr/lib/libneko.so
		
		# Cleanup
		
		rm -r neko-1.8.2-linux64
		rm neko-1.8.2-linux64.tar.gz
		
		
	else
		
		
		echo ""
		echo "-----------------------------------"
		echo "    Downloading Neko (32-bit)"
		echo "-----------------------------------"	
		
		wget -c http://nekovm.org/_media/neko-1.8.2-linux.tar.gz
		
		
		echo ""
		echo "-----------------------------------"
		echo "    Installing Neko"
		echo "-----------------------------------"
		
		
		# Extract and copy files to /usr/lib/neko
		
		tar xvzf neko-1.8.2-linux.tar.gz
		sudo mkdir -p /usr/lib/neko
		sudo cp -r neko-1.8.2-linux/* /usr/lib/neko
		
		# Add symlinks
		
		sudo rm -rf /usr/bin/neko
		sudo rm -rf /usr/bin/nekoc
		sudo rm -rf /usr/bin/nekotools
		sudo rm -rf /usr/lib/libneko.so
		
		sudo ln -s /usr/lib/neko/neko /usr/bin/neko
		sudo ln -s /usr/lib/neko/nekoc /usr/bin/nekoc
		sudo ln -s /usr/lib/neko/nekotools /usr/bin/nekotools
		sudo ln -s /usr/lib/neko/libneko.so /usr/lib/libneko.so
		
		
		# Cleanup
		
		rm -r neko-1.8.2-linux
		rm neko-1.8.2-linux.tar.gz
		
		
	fi
	
	
	# Install libgc, which is required for Neko
	
	sudo apt-get install libgc-dev
	
	
	echo ""
	echo "-----------------------------------"
	echo "    Downloading Haxe"
	echo "-----------------------------------"	
	
	wget -c http://haxe.org/file/haxe-2.10-linux.tar.gz
	
	
	echo ""
	echo "-----------------------------------"
	echo "    Installing Haxe"
	echo "-----------------------------------"
	
	
	# Extract and copy files to /usr/lib/haxe
	
	tar xvzf haxe-2.10-linux.tar.gz
	sudo mkdir -p /usr/lib/haxe
	sudo cp -r haxe-2.10-linux/* /usr/lib/haxe
	
	
	# Add symlinks
	
	sudo rm -rf /usr/bin/haxe
	sudo rm -rf /usr/bin/haxelib
	sudo rm -rf /usr/bin/haxedoc
	
	sudo ln -s /usr/lib/haxe/haxe /usr/bin/haxe
	sudo ln -s /usr/lib/haxe/haxelib /usr/bin/haxelib
	sudo ln -s /usr/lib/haxe/haxedoc /usr/bin/haxedoc
	
	
	if [ `uname -m` = 'x86_64' ]; then
		
		
		# Need 32-bit support
		
		sudo apt-get install ia32-libs
		
		
		# Need to recompile haxelib for 64-bit Neko
		
		haxe /usr/lib/haxe/std/tools/haxelib/haxelib.hxml
		sudo cp haxelib /usr/lib/haxe/haxelib
		rm index.n
		rm haxelib.n
		rm haxelib
		
		
		# Need to recompile haxedoc for 64-bit Neko
		
		haxe /usr/lib/haxe/std/tools/haxedoc/haxedoc.hxml
		sudo cp haxedoc /usr/lib/haxe/haxedoc
		rm haxedoc.n
		rm haxedoc
		
		
	fi
	
	
	# Set up haxelib
	
	sudo mkdir -p /usr/lib/haxe/lib
	sudo chmod -R 777 /usr/lib/haxe/lib
	sudo haxelib setup /usr/lib/haxe/lib
	
	
	# Cleanup
	
	rm -r -f haxe-2.10-linux
	rm haxe-2.10-linux.tar.gz
	
	
fi


echo ""
echo "-----------------------------------"
echo "    Installing HXCPP"
echo "-----------------------------------"

wget -c http://www.nme.io/builds/hxcpp-2.10.3.zip
haxelib test hxcpp-2.10.3.zip
rm hxcpp-2.10.3.zip


echo ""
echo "-----------------------------------"
echo "    Installing NME"
echo "-----------------------------------"

# Install libssl, which is required for the command-line tools

sudo apt-get install g++ libssl0.9.8

# Download and install NME

haxelib install nme

# Add "nme" command shortcut

sudo haxelib run nme setup


echo ""
echo "-----------------------------------"
echo "    Installing additional libraries"
echo "-----------------------------------"

haxelib install actuate
haxelib install swf
haxelib install svg


echo ""
