#!/usr/bin/env python3

import sys, getopt
#from future.backports.test.pystone import FALSE

def main(argv):
    inputFile = ''
    outputDir = '.'
    CNs = {}
    quiet = False
    
    try:
        opts, args = getopt.getopt(argv,"hqi:d:",["input-file=","output-dir="])
    except getopt.GetoptError:
        print ('ssl_split_scans.py -i <inputfile> -d <output_dir>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('ssl_split_scans.py -i <inputfile> -d <output_dir>')
            sys.exit()
        if opt == '-q':
            quiet = True           
        elif opt in ("-i", "--input-file"):
            inputFile = arg
        elif opt in ("-d", "--output-dir"):
            outputDir = arg            
    
    if not quiet:
        print ("ssl_split scans - splits a nmap-parse-output file into scan directories")
    # Open the file and read through file
    file = open(inputFile, 'r')
    Lines = file.readlines()
    file.close()
 
    count = 0
    # Strips the newline character
    for line in Lines:
        count += 1
        
        # Set variables to falsee
        NewHostname = False
        NewIP = False
        
        # Split the line into its components
        split = line.split()
        splitIP = split[0].split(':')
        ip = splitIP[0]
        port = splitIP[1]
        hostname = split[1]
        
        # If the CN is not defined for the hostname, then define it
        if CNs.get(hostname) == None:
            CNs[hostname] = {}
            NewHostname = True
        
        # if the IP address is not associated to hostname, then add it too the host list
        if CNs[hostname].get(ip) == None:
            CNs[hostname][ip] = len(CNs[hostname])+1
            NewIP = True
    
        # Output hostname:port combo to ips file
        file = open(outputDir + '/scan_ips'+str(CNs[hostname][ip]), 'a')
        file.write("{}:{}\r".format(hostname, port))
        file.close()
        
        # If this is a new hostname or new IP, then write it out to an appropriate file 
        if NewHostname or NewIP:
            file = open(outputDir + '/scan_hosts'+str(CNs[hostname][ip]), 'a')
            file.write("{}\t{}\r".format(ip, hostname))
            file.close()
                   
#        print("Line{}: {}".format(count, line.strip()))

if __name__ == "__main__":
    main(sys.argv[1:])