#!/bin/bash

USER=$1
PASSWD=$2

ftp -n -v www.haxenme.org << EOT
binary
user $USER $PASSWD
prompt
put ndll/$3 /public_html/haxenme/builds/ndll/$3
bye
EOT