# certscan

NOTE:  THIS IS CURRENTLY UNDER DEVELOPMENT AND VERY EXPERIMENTAL.  BY ALL MEANS DOWNLOAD AND SEE WHAT I AM DOING, OR EVEN BETTER ADD TO THE PROJECT.  THIS IS VERY ALPHA UNDER FLUID CHANGES.  DON'T EXPECT IT TO WORK AT THE MOMENT

TO DO:  
 - Error handling in scripts
 - fix up Dockerfile for certscan 
 - do the elastic dashboards for testssl.sh-masscan


## Purpose
Scans networks for port with certificates, scans them, and then loads into Elastic

## How it works
There are a number of really great projects out there to do what I wanted to do.  This brings them togeather for what I want.  So, we have NMAP that scans networks.  Then, we use NMAP-Parse-output to extract out of the NMAP results the ports etc that we want.  We then break that output, and define how many different scans we need to scan all the different IPs and hosts for the certificates.  We then scan any named locations/ports.  Once that is done, then we use an updated Testssl.sh-masscan to import the results into Elastic.  See - easy

## Defining what is scanned
We use NMAP to extract ther certificate name of each certificate that it finds.  By doing this, we ensure that we use that name when scanning the certificate to try and get around a certificate name mismatch.  Because of this, we might have several circumstances where we might end up scanning the wrong endpoint.  Some example circumstances are:

*when there are SAN certificates across multiple hosts*  
scenario 1  
Think about you have a SAN certificate with multiple host names.  We are only interested is getting the CN, or the main name.  Lets assume that we get a CN or *host.example.com*.  If we find this certificate across multiple hosts, we need to ensure that when we talk to *host.example.com*, that we are actually talking to the host we want.  Therefore, we split the list up as required to ensure that this happens.

Elasticsearch index appends the year and month to the index name

# Forcing internal sites to be tagged as external
When you are performing a scan internally, there may be some hosts that are also available from the outside, and you want to force those hosts to be tagged as External.  To do this, put the host IPs or hostnames into the `EXTERNAL_HOSTS` variable of the settings file.  This will get copied to the CSV that is produced by testssl.sh.  Upon import. the certificate will be tagged as an external certificate.

to run a sample import  
``python3 /usr/local/bin/import_testssl.sh_csv_to_ES.py --user elastic --password S7WZUvLZi9rBPjnFDFd0 --index testssl workdir/mail.thesmithcave.nz_p110-20220416-1112.csv ``


#TODO:
 - check time on file to time in ES on imported file
 - scan file with IP only to check default filename to see if conforms to original regex
 - tags - allow defining
 
 - change to use ECS for usability -testing
 - option to import only, or scan only - done but needs testing
 
 #DONE:
  - fix masscan unable to accept --elasticsearch command line option correctly - TESTING - only allowed one host
 - add date/month to index name - DONE
  - add ability to determine programatically what is external hosts when scanned internally - DONE
 