#!/usr/bin/env python3

# Purpose of this script is to load the hosts file with additional hosts for the scan
# options
#  -i, --input-file  name of the file to load
#  -d                remove entries from the hosts file
import sys, getopt
import re
#from future.backports.test.pystone import FALSE

def main(argv):
    inputFile = ''
    deleteOnly = False
    quiet = False
   
    try:
        opts, args = getopt.getopt(argv,"hqi:d",["input-file=","delete-only"])
    except getopt.GetoptError:
        print ('ssl_load_hosts.py -i <inputfile> -d')
        print ('  -i File to load, already in the hosts file format')
        print ('  -d only delete the hosts file')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('ssl_split_scans.py -i <inputfile> -d')
            print ('  -i File to load, already in the hosts file format')
            print ('  -d only delete the hosts file')
            sys.exit()
        if opt == '-q':
            quiet = True           
        elif opt in ("-i", "--input-file"):
            inputFile = arg
        elif opt in ("-d", "--delete"):
            deleteOnly = True            
    
    if not quiet:
        print ("ssl_load_hosts.py scans - splits a nmap-parse-output file into scan directories")
    # Read in the file
    if not deleteOnly:
        file = open(inputFile, 'r')
        linesToAdd = file.read()
        file.close()
 
    # Clear out the hosts file
    hostsHandle = open('/etc/hosts', 'r')
    hosts = hostsHandle.read()
    hostsHandle.close()
    
    hosts = re.sub(r"##### Begin auto-added entries #####.*?##### End auto added entries #####", '', hosts, 0, re.DOTALL)
    
    if not deleteOnly:
        hosts = "{}\n##### Begin auto-added entries #####\n{}\n##### End auto added entries #####".format(hosts,linesToAdd)
    
    # remove blank lines
    hosts = re.sub(r"\n\n", "\n", hosts, 0, re.DOTALL)
    
     # write out the hosts file
    hostsHandle = open('/etc/hosts', 'w')
    hostsHandle.write(hosts)
    hostsHandle.close()   
    
if __name__ == "__main__":
    main(sys.argv[1:])