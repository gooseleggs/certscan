#!/bin/bash
#############################################################
# CERTSCAN.SH
#
# Written by Kelvin Smith
#
#############################################################

NMAP_OPTIONS=${NMAP_OPTIONS:="T4 "}
NMAP_SCANFILE=${NMAP_SCANFILE:="nmap_scan"}
WORKDIR=${WORKDIR:=/home/certscan/certscan/workdir}
TESTSSL_OPTIONS=${TESTSSL_OPTIONS:"--openssl-timeout=60 -q --overwrite "}
NAMED_SCANFILE=${NAMED_SCANFILE:="named_scan"}

# Username for connection
USERNAME=${USERNAME:=user}
# Password for SSL connection
PASSWORD=${PASSWORD:="password"}
# The hostname ip/url and port
ELASTICHOST=${ELASTICHOST:="127.0.0.1:9200"}
# The prefix of the index to create in Elastic.  The year and month are appended to the index name automatically
INDEX=${INDEX:="testssl"}
# The following variable is a space separated list of hosts and urls that should be treated as external sites, even if internal
EXTERNAL_HOSTS=${EXTERAL_HOSTS:=""}
# Scan the networks
DO_SCAN=${DO_SCAN:=true}
# Import the results
DO_IMPORT=${DO_IMPORT:=true}

echo "CERTSCAN.sh - automate finding, scanning and adding to Elastic SSL certs on networks"

# Read in config settings if file exists
if [ -f $WORKDIR/settings.conf ]; then
	echo "Reading in configuration settings"
	. $WORKDIR/settings.conf
fi

# process command line parameters
while [ -n "$1" ]
do
	case "$1" in
		-s) echo "Scan only"; DO_IMPORT=false ;;
		-i) echo "Import only"; DO_SCAN=false ;;
		-h) echo "Commandline options: -s to scan only.  -i to import files only"; exit ;;
		*) echo "Error: $1 is not an option"; exit ;;
	esac
	shift
done

if [ "$DO_SCAN" = true ]; then
	echo "Clearing out any previous results"
	rm -f $WORKDIR/*.csv
	rm -f $WORKDIR/*.log
	rm -f $WORKDIR/*.json
	rm -f $WORKDIR/scan_*
	rm -f $WORKDIR/testssl.run
	rm -f $WORKDIR/npo
	rm -f $WORKDIR/nmap_results.xml

	# If the workdir does not exist, then exit
	if [ ! -d $WORKDIR ]; then
		echo "Work directory ($WORKDIR) does not exist creating..."
		mkdir -p $WORKDIR
	fi

	# If there is a nmap_scan file, then kick off NMAP to find the hosts
	if [ -f $WORKDIR/$NMAP_SCANFILE ]; then
		echo "Scanning file $WORKDIR/$NMAP_SCANFILE"
		nmap  -oX $WORKDIR/nmap_results.xml --script ssl-cert $NMAP_OPTIONS -iL $WORKDIR/$NMAP_SCANFILE
	fi

	# If we have an nmap scan file, then we had success from NMAP to some extent.  parse out the certs and hosts
	if [ -f $WORKDIR/nmap_results.xml ]; then
		echo "parsing NMAP results file $WORKDIR/nmap_results.xml"
		nmap-parse-output $WORKDIR/nmap_results.xml ssl-common-name  > $WORKDIR/npo
	fi

	# if we have an npo output file, lets get the scanning order sorted
	if [ -f $WORKDIR/npo ]; then
		echo "parsing nmap-parse-output results to generate scan file and orders"
		python3 ssl_split_scans.py -i $WORKDIR/npo -d $WORKDIR -q
	fi

	echo "Parsing scan files"
	# now lets loop through the host files and do some scans
	for f in $WORKDIR/scan_ips*; do
		if [ ! -e "$f" ]; then
			echo "No scan files found...exiting"
			break
		fi 
		echo "Processing $f file..";
		
		# remove any current run file
    	rm -f  $WORKDIR/testssl.run
     
		# Get the number of the file
		NUMBER=$(echo $f | tr -dc '0-9')
	
		# empty out hosts files from any previous run
		python3 ssl_load_hosts.py -d -q
	
		# If the equivalent hosts file exists, then load it in
		if [ -f $WORKDIR/scan_hosts$NUMBER ]; then
			echo "  Loading hosts file"
			python3 ssl_load_hosts.py -i $WORKDIR/scan_hosts$NUMBER -q
		fi
	
		# generate the scan file
		generate_scan_file.py -a "$TESTSSL_OPTIONS --csvfile $WORKDIR"  $WORKDIR/scan_ips$NUMBER > $WORKDIR/testssl.run
	
		# run the scan file
		if [ -f $WORKDIR/testssl.run ]; then
			if [ ! -e "$f" ]; then
				echo "No scan files found...exiting"
				exit
			fi 
			echo "Starting SSL tests for iteration $NUMBER..."
			parallel < $WORKDIR/testssl.run
		fi
	done

	# empty out hosts files to exit clean
	python3 ssl_load_hosts.py -d -q

	#echo $WORKDIR/$NAMED_SCAN
	# If there is a named scan file, then process/scan that
	if [ -f $WORKDIR/$NAMED_SCANFILE ]; then
		echo "Processing named scan file ($NAMED_SCANFILE)";	
		# Generate the parallels file
		generate_scan_file.py -a "$TESTSSL_OPTIONS --csvfile $WORKDIR"  $WORKDIR/$NAMED_SCANFILE > $WORKDIR/testssl.run
		parallel < $WORKDIR/testssl.run
	fi

	# We now append our external hosts into the CSV for post processing - we delete to start, so doubleups should not occur
	echo "Appending external_hosts to files for processing ..";
	for f in $WORKDIR/*.csv; do
		if [ ! -e "$f" ]; then
			echo "No scan files found...exiting"
			exit
		fi 	
		echo '"external_hosts","","","INFO","'$EXTERNAL_HOSTS'","",""'	>> $f
	done
fi

if [ "$DO_IMPORT" = true ]; then
	# Now we have everything, lets load it into Elastic if we can
	echo "Importing result files into Elastic..."
	#python3 /usr/local/bin/import_testssl.sh_csv_to_ES.py --user $USER --password $PASSWORD --index $INDEX --elasticsearch "$ELASTICHOST" $WORKDIR/*.csv 
	python3 /usr/local/bin/import_testssl.sh_csv_to_ES.py --user $USERNAME --password $PASSWORD --index $INDEX --elasticsearch $ELASTICHOST $WORKDIR/*.csv	 
fi