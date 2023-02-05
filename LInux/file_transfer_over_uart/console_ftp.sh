#!/bin/bash
# Author : Yaoyang(John) Wang
# by 2023-02

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
COLOR_BLUE="\e[34m"
COLOR_MAGENTA="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_GRAY="\e[37m"
COLOR_WHITE="\e[97m"
COLOR_RESET="\e[0m"

UART_DEV=""
SRC_FILE=""

wait_key() {
	if [ $# -gt 0 ]; then
		sleep 5;
		echo -e "$COLOR_RESET \n$@\n";
	else
		sleep 1;
		echo -e "$COLOR_RESET \nPress any key to continue.\n";
	fi
	echo -e "$COLOR_GREEN";
	while [ true ] ; do
		read -t 30 -n 1
		if [ $? = 0 ] ; then return; fi
	done
}

tty_send() {
	echo -n -e "$@" > $UART_DEV;
}

tty_commit() {
	tty_send "$@";
	echo " " > $UART_DEV;
}

install_lrz() {
	SRC_FILE=lrz.ipk
	MD5_SRC=`md5sum $SRC_FILE`
	j=0;
	tty_commit "cd /tmp && rm lrz.txt";
	tty_commit "echo \"$MD5_SRC\" > lrz_src.md5";
	tty_send "echo \""
	for i in $(cat lrz.txt);
		do
			j=$(($j+1));
			tty_send "$i " > $UART_DEV;
			if [ $(expr $j % 32) -eq 0 ]; then
				tty_commit "\" >> lrz.txt" > $UART_DEV;
				tty_send "echo \"" > $UART_DEV;
				echo -n -e "#"
			fi;
		done;
	tty_commit "\" >> lrz.txt";
	echo -e "$COLOR_GREEN \nConverting..."
	tty_commit "for i in \$(cat lrz.txt) ; do printf \"\x\$i\" ; done > lrz.ipk";
	cat $UART_DEV &
	tty_commit "sleep 3 && rm lrz.txt && md5sum lrz.ipk > lrz_dst.md5";
	tty_commit "echo \"Verify hash code:\" && cat lrz_src.md5 && cat lrz_dst.md5";
	tty_send "if cmp -l lrz_src.md5 lrz_dst.md5; then echo -e '\nUpload OK!\n' &&";
	tty_commit " opkg install lrz.ipk; else echo -e '\nMD5 Failed!\n'; fi";
	echo -e "$COLOR_GREEN \nVerifying..."
	wait_key "Press ENTER after xyzmodem tool 'lrzsz' installed..."
	killall cat
}

upload_file() {
	tty_commit "cd /tmp && rm $SRC_FILE";
	tty_commit "echo \"$(md5sum $SRC_FILE)\" > src.md5";
	tty_commit "lrz -Z";
	sz --zmodem $SRC_FILE > $UART_DEV < $UART_DEV;
	cat $UART_DEV &
	tty_commit "md5sum $SRC_FILE > dst.md5 && echo \"Verify hash code:\"";
	tty_commit "sleep 1 && cat src.md5 && cat dst.md5";
	tty_commit "if cmp -l src.md5 dst.md5; then echo -e '\nChecksum OK!\n'; else echo -e '\nMD5 Failed!\n'; fi";
	wait_key
	killall cat
}

file_transfer() {
	if [ $# -eq 1 ]; then
		echo -e "$COLOR_BLUE Installing xyz/modem tool over console..."
		echo -e "$COLOR_GREEN Uploading lrz.ipk through $1..."
		if [ -c $1 ]; then
			UART_DEV=$1
			install_lrz
		else
			echo -e "$COLOR_RED $1 is not a valid device name";
		fi
	elif [ $# -gt 1 ]; then
		UART_DEV=$1
		SRC_FILE=$2
		
		if [ -c $UART_DEV ]; then
			if [ -f "$SRC_FILE" ]; then
				echo -e "$COLOR_MAGENTA Uploading $SRC_FILE through $1..."
				upload_file $@
			else
				#echo -e "$COLOR_RED The specified file '$2' is not exist."
				cat $UART_DEV &
				echo -e "$COLOR_GREEN$SRC_FILE$COLOR_RESET is not a file, Sending $COLOR_GREEN$SRC_FILE$COLOR_RESET as a commands...";
				echo -n -e "${@:2}" > $UART_DEV;	echo " " > $UART_DEV;
				sleep 3;
				killall cat
			fi
		else
			echo -e "$COLOR_RED $1 is not a valid device name";
		fi
	else
		echo -e "$COLOR_GREEN Usage :"
		echo -e "$COLOR_GREEN $0 DEV_NAME [FILE_NAME]"
		echo -e "$COLOR_GREEN     DEV_NAME     UART device being used to transfer files. (e.g. /dev/ttyUSB0)."
		echo -e "$COLOR_GREEN     FILE_NAME    Specify the file that need to be uploaded over the TTY console."
		echo -e "$COLOR_GREEN                  If no file is specified, it will try to install 'lrzsz' on the target board."
		echo -e "$COLOR_GREEN                  If specified file not exist, the file name be treated as a command to the console."
	fi
	echo -e "$COLOR_RESET"
}

file_transfer "$@"

