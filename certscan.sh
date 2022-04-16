#!/bin/bash
#############################################################
# CERTSCAN.SH
#
# Written by Kelvin Smith
#
#############################################################

NMAP_OPTIONS="T4"
NMAP_SCANFILE="nmap_scan"
WORKDIR=/home/certscan/workdir/workdir
TESTSSL_OPTIONS="--warnings=batch --openssl-timeout=60 --overwrite "
NAMED_SCANFILE="named_scan"

echo "CERTSCAN.sh - automate finding, scanning and adding to Elastic SSL certs on networks"


echo "Clearing out any previous results"
rm -f $WORKDIR/*.csv
rm -f $WORKDIR/*.log
rm -f $WORKDIR/*.json
rm -f $WORKDIR/scan_*
rm -f $WORKDIR/testssl.run


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
	ssl_split_scans.py -i $WORKDIR/npo -d $WORKDIR
fi

# TESTING
rm $WORKDIR/scan_ips*

# now lets loop through the host files and do some scans
for f in $WORKDIR/scan_ips*; do
	echo "Processing $f file..";
	
	# remove any current run file
    rm -f  $WORKDIR/testssl.run
     
	# Get the number of the file
	NUMBER=$(echo $f | tr -dc '0-9')
	
	# empty out hosts files from any previous run
	ssl_load_hosts.py -d
	
	# If the equivalent hosts file exists, then load it in
	if [ -f $WORKDIR/scan_hosts$NUMBER ]; then
		echo "  Loading hosts file"
		ssl_load_hosts.py -i $WORKDIR/scan_hosts$NUMBER
	fi
	
	# generate the scan file
	generate_scan_file.py -a "$TESTSSL_OPTIONS --csvfile $WORKDIR"  $WORKDIR/scan_ips$NUMBER > $WORKDIR/testssl.run
	
	# run the scan file
	if [ -f $WORKDIR/testssl.run ]; then
		echo "Starting SSL tests for iteration $NUMBER..."
		parallel < $WORKDIR/testssl.run
	fi
done

# empty out hosts files to exit clean
ssl_load_hosts.py -d

echo $WORKDIR/$NAMED_SCAN
# If there is a named scan file, then process/scan that
if [ -f $WORKDIR/$NAMED_SCANFILE ]; then
	echo "Processing named scan file ($NAMED_SCANFILE)";	
	# Generate the parallels file
	generate_scan_file.py -a "$TESTSSL_OPTIONS --csvfile $WORKDIR"  $WORKDIR/$NAMED_SCANFILE > $WORKDIR/testssl.run
	parallel < $WORKDIR/testssl.run
fi



