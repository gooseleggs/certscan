# certscan

## Purpose
Scans networks for ports with certificates, perform SSL tests against them, and then load into Elastic.

## How it works
There are a number of really great projects out there to do what I wanted to do.  This brings them together for what I want.  So, we have NMAP that scans networks.  Then, we use NMAP-Parse-output to extract out of the NMAP results the ports and certificate names that we want.  We then split the output, and define how many different scans we need to scan all the different IPs and hosts for the certificates.  Now we scan with Testssl.sh-masscan (updated) to perform tests against these results.  We then scan any named locations/ports.  Once that is done, then we import into Elasticsearch.

### Scanning common name of certificates
We use NMAP to find the port, ip address and extract the certificate name of each certificate that it finds.  By doing this, we use the certificate name when scanning the certificate to try and get around a certificate name mismatch.  We do this by manipulating the hosts file on the local system.  Because of manipulating the hosts file, we might have several circumstances where we end up scanning the wrong endpoint.  Some example circumstances are:

*when there are SAN certificates across multiple hosts*  
scenario 1  
Think about you have a SAN certificate with multiple host names.  We are only interested is getting the CN, or the main name.  Lets assume that we get a CN of *host.example.com*.  If we find this certificate across multiple hosts, we need to ensure that when we talk to *host.example.com*, that we are actually talking to the host we want.  Therefore, we split the list as required to ensure that this happens.

# Options
Options are passed by environment variables.  The following environment variables are defined:
  - *NMAP_OPTIONS* Options to be passed to NMAP.  These default is `"T4 "`
  - *NMAP_SCANFILE* The name of the file containing the networks to be scanned.  This is a line separated, NMAP compatibile list of hosts/networks to be scanned.  The default name is `"nmap_scan"`
  -  *WORKDIR* The directory where all the work gets done.  This is the folder where the *NMAP_SCANFILE* and *NAMED_SCANFILE* will reside.  The default is `"/home/certscan/certscan/workdir"`
  - *TESTSSL_OPTIONS* options to be passed through to the testssl.sh program.  The default options are `"--openssl-timeout=60 -q --overwrite "`
  - *NAMED_SCANFILE* File containing additional hosts/urls:port combinations to be scanned.  The name of the file by default is `"named_scan"`
  - *USERNAME* Username to connect to Elastic.  Default is `user`
  - *PASSWORD* Password to connect to Elastic.  Default is `password`
  - *ELASTICHOST* Host and port name to connect to Elastic.  Default is `127.0.0.1:9200`
  - *INDEX* Name of the index to be used in Elastic.  This application will append the Month/Year onto the *INDEX* name.  The default is `testssl`
  - *EXTERNAL_HOSTS* Space separated list (use quotes) of hosts that should be tagged as external, even if they are on a private IP Address.  Default is `""`
  - *DO_SCAN* If true, then it will scan and test all SSL hosts/ports that are found, and create files ready for importation.  Default is `true`
  - *DO_IMPORT* If true, then scan results will be imported into Elastic.  Default is `true`

As well as passing the variables in through environment variables, a BASH compatible file can be used to set the values.  This file must reside in the *WORKDIR* directory and be called `settings.conf`.  Any or all of the settings can be overridden as required. The settings file overrides any environment variables passed through.  An example of overriding settings in the file is as follows:

```
# The following variable is a space separated list of hosts and urls that should be treated as external sites, even if internal
EXTERNAL_HOSTS="192.168.9.23"
```
 
## Forcing internal sites to be tagged as external
When you are performing a scan internally, there may be some hosts that are also available from the outside, and you want to force those hosts to be tagged as External.  To do this, put the host IPs or hostnames into the `EXTERNAL_HOSTS` variable of the settings file.  This will get copied to the CSV that is produced by testssl.sh.  Upon import. the certificate will be tagged as an external certificate.

## Forcing scanning of sites
When NMAP does a scan, it might find a host:port combination, but if you have, for example a number of web servers running on that port, it will not find the other servers.  By passing through/creating the *NAMED_SCANFILE* file, a list of URLs:ports or ip:port combinations in testssl.sh format will also be scanned and added to the output.  This way, a complete picture can be found.

## Dashboard
The dashboard is distributed as part of my testssl.sh-masscan fork.  Therefore, jump to that repo to download the dashbaord.  The repo is located here: [https://github.com/gooseleggs/testssl.sh-masscan]

# Docker
To build this as a docker image, clone the git repository, then run

`docker build -t certscan.sh:latest .`

or use the version already in the repository.

To run the docker container, create a file with the networks to scan, and then map it through to the container, such as 
`docker run --rm -it -v ./nmap_scan:/home/certscan/certscan/workdir/nmap_scan  gooseleggs/certscan.sh:1.0`
 
Additional settings can be passed through, using environment variables, such as

`docker run --rm -it -v ~/Documents/Projects/certscan/workdir/nmap_scan:/home/certscan/certscan/workdir/nmap_scan -e ELASTIC_HOST "192.168.1.1:922" gooseleggs/certscan.sh:1.0`

# Known issues
Currently there is an issue with the timestamp on the imports.  This is because the time is dealt with in UTC.  