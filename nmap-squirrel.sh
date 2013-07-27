#!/bin/bash

DATE=$(date +"%Y%m%d_%H%M%S")
echo -e "Executed $0 at $DATE"
PWD=$(pwd)


function HELP () {
echo "This program was built for all of your Nmap Needs. Please note this program will be loud on the network"
echo " To run in the background: nohup $0 <options> &"
echo "###########################################################"
echo " -h This Help message"
echo " -t <target file>, contents=IP subnet"
echo " -c <subnet file>, Scan with this subnet only"
echo " -r Turn off Root user requirement"
echo " -b Turn on brute force password scripts"
echo " -s brute force snmp accounts"
echo " -t brute force telnet accounts"
echo " -H brute force http accounts"
echo " -m brute force mysql accounts"
echo " -e <email address>, Email user when scanning is complete"
echo "###########################################################"
}

function DoesNMAPExist () {
echo "Function:DoesNMAPExist"
#Check if NMAP is installed
NMAP=$(/bin/whereis nmap | awk '{print $2}')
$NMAP -V |grep "Nmap version" 2>/dev/null
	if [ $? -ne '0' ] ; then echo -e "Error: Unable to find NMAP \n PATH=$NMAP" ; echo -e "Nmap found; PATH=$NMAP" 
	fi
if [ ! -s $TARGET ] ; then
echo "Error: Target file is empty"
exit
fi
}

function NMAP () {
echo "Function:NMAP"
#Run NMAP Scripts
	if [ -z "$cFLAG" ] ;then
for X in `ls -a |grep .nmap.target$`; do
	Y=$(echo $X|awk -F'.' '{print $2}') 
	nmap -sT -oA $Y -iL $X
	mkdir ARCHIVE 2>/dev/null
	mv $X ARCHIVE/$X-$DATE
done
	else 
	nmap -p21,3306,25 -sT -oA $TARGET -iL $TARGET
	fi
####CHECK AND RUN based on GREP
if [ ! -z "$httpFLAG" ] ;then
	echo "I Need to parse and excecute HTTP brute force"
	cat $TARGET.gnmap |grep 80 | awk '{print $2}'  >>$TARGET_http-brute.ips
	nmap --script /usr/share/nmap/scripts/http-brute.nse -vv -iL $TARGET_http-brute.ips -oA $TARGET_http-brute
		elif [ ! -z "$telnetFLAG" ] ;then
		echo "I need to parse and execute Telnet brute force"
		cat $TARGET.gnmap |grep 21 |awk '{print $2}' >>$TARGET_telnet-brute.ips
		nmap --script /usr/share/nmap/scripts/telnet-brute.nse -vv -iL $TARGET_telnet-brute.ips -oA $TARGET_telnet-brute
			elif [ ! -z "$mysqlFLAG" ] ;then
			echo "I need to parse and execute Mysql brute force"
			cat $TARGET.gnmap |grep 3306 |awk '{print $2}' >>$TARGET_mysql-brute.ips
                nmap --script /usr/share/nmap/scripts/mysql-brute.nse -vv -iL $TARGET_mysql-brute.ips -oA $TARGET_mysql-brute
				elif [ ! -z "$snmpFLAG" ] ; then
				echo "I need to parse and execute SNMP brute force"
			cat $TARGET.gnmap |grep 21 |awk '{print $2}' >>$TARGET_snmp-brute.ips
	                nmap --script /usr/share/nmap/scripts/snmp-brute.nse -vv -iL $TARGET_snmp-brute.ips -oA $TARGET_snmp-brute
fi
}


function CREATE () {
echo "Function:CREATE"
#Create subnets to scan
count=0
TOTAL=$(cat $TARGET|wc -l)
echo "Total number of Entries = $TOTAL"
while [ $count -le $TOTAL ] ; do
#echo "counter = $count"
SUB=$(cat -n $TARGET | grep " $count" |awk '{print $3}')
	if [ ! -z "$SUB" ] ; 
	then
echo "$(cat -n $TARGET | grep " $count" |awk '{print $2}')" >>.$SUB.nmap.target
	fi
count=$(echo "$count + 1" |bc)
done
NMAP
}

function YorN () {
echo "Function:YorN"
#Continue?
}

function Clean () {
echo "Function:Clean"
#Clean up temp files
}

hFLAG=
tFLAG=
rFLAG=
bFLAG=
cFLAG=
allFLAG=
eFLAG=
mysqlFLAG=
telnetFLAG=
snmpFLAG=
ftpFLAG=
httpFLAG=
while getopts ":ht:re:c:bHfstm" opts;do
	case $opts in 
		h)echo "hflag"; hFLAG=1 ;;
		t)echo "tflag"; tFLAG=1 ; TARGET="$OPTARG";;
		r)echo "rflag"; rFLAG=1 ;;
		m)echo "mysqlflag"; mysqlFLAG=1 ;;
		t)echo "telnetflag"; telnetFLAG=1 ;;
		s)echo "snmpflag"; snmpFLAG=1 ;;
		f)echo "ftpflag"; ftpFLAG=1 ;;
		H)echo "httpflag"; httpFLAG=1 ;;
		a)echo "allflag"; allFLAG=1 ;;
		b)echo "bflag"; bFLAG=1 ;;
		c)echo "cflag"; cFLAG=1 ; TARGET="$OPTARG" ;;
		e)echo "eflag"; eFLAG=1 ; EMAIL="$OPTARG" ;;
		?) echo "Error: Unknown Option- $@" ; exit ;;
	esac
done

if [ ! -z "$hFLAG" ] ;then
	#HELP FUNCTION
	HELP
	exit
fi

if [ ! -z "$tFLAG" ] ;then
	echo "Target File = $TARGET"
	DoesNMAPExist
	CREATE
fi

if [ ! -z "$cFLAG" ] ;then
	echo "Files have already been created"
	#SHOW CREATED FILES AND ASK USER TO CONTINUE
	DoesNMAPExist
	NMAP
fi

if [ -z "$rFLAG" ] ;then
	if [ $(id -u) -ne '0' ] ;then
	echo -e "Error: Must be executed as root \nOr use "-r" flag to run as current user" 	
	exit
	fi
fi

if [ ! -z "$eFLAG" ] ;then
	#Send email to user when complete
	#mail VS mutt## maybe alias
	echo "Not implemented yet. please write me"
fi
