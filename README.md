# certscan

##Purpose
Scans networks for port with certificates, scans them, and then loads into Elastic

##How it works
There are a number of really great projects out there to do what I wanted to do.  This brings them togeather for what I want.  So, we have NMAP that scans networks.  Then, we use NMAP-Parse-output to extract out of the NMAP results the ports etc that we want.  We then break that output, and define how many different scans we need to scan all the different IPs and hosts for the certificates.  We then scan any named locations/ports.  Once that is done, then we use an updated Testssl.sh-masscan to import the results into Elastic.  See - easy

## Defining what is scanned
We use NMAP to extract ther certificate name of each certificate that it finds.  By doing this, we ensure that we use that name when scanning the certificate to try and get around a certificate name mismatch.  Because of this, we might have several circumstances where we might end up scanning the wrong endpoint.  Some example circumstances are:

*when there are SAN certificates across multiple hosts*  
scenario 1  
Think about you have a SAN certificate with multiple host names.  We are only interested is getting the CN, or the main name.  Lets assume that we get a CN or *host.example.com*.  If we find this certificate across multiple hosts, we need to ensure that when we talk to *host.example.com*, that we are actually talking to the host we want.  Therefore, we split the list up as required to ensure that this happens.

Blah blash - more to come