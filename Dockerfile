FROM python:3

RUN apt update && \
    apt -y upgrade && \
    apt install -y nmap bsdmainutils dnsutils xsltproc parallel && \
	useradd -m certscan && \
	cd home/certscan && \
	git clone https://github.com/drwetter/testssl.sh.git && \
	ln -s /home/certscan/testssl.sh/testssl.sh /usr/local/bin && \
	git clone https://github.com/gooseleggs/testssl.sh-masscan.git && \
	ln -s /home/certscan/testssl.sh-masscan/generate_scan_file.py /usr/local/bin && \
	ln -s /home/certscan/testssl.sh-masscan/import_testssl.sh_csv_to_ES.py /usr/local/bin && \
	git clone https://github.com/gooseleggs/certscan.git && \
	ln -s /home/certscan/certscan/certscan.sh /usr/local/bin && \
	ln -s /home/certscan/certscan/ssl_load_hosts.py /usr/local/bin && \
	ln -s /home/certscan/certscan/ssl_split_scans.py /usr/local/bin
	
RUN cd /home/certscan/ && git clone https://github.com/ernw/nmap-parse-output.git && \
	ln -s /home/certscan/nmap-parse-output/nmap-parse-output /usr/local/bin && \
	mkdir -p /home/certscan/workdir

RUN python3 -m pip install elasticsearch_dsl tzlocal
COPY ./certscan.sh /usr/local/bin
# Install testssl.sh-masscan    
    
#RUN apk update && \
#    apk upgrade && \
#    apk add bash procps drill git coreutils libidn curl socat openssl xxd && \
#    rm -rf /var/cache/apk/* && \
#    addgroup testssl && \
#    adduser -G testssl -g "testssl user" -s /bin/bash -D testssl && \
#    ln -s /home/testssl/testssl.sh /usr/local/bin/ && \
#    mkdir -m 755 -p /home/testssl/etc /home/testssl/bin

#USER testssl
WORKDIR /home/certscan/

#COPY --chown=testssl:testssl etc/. /home/testssl/etc/
#COPY --chown=testssl:testssl bin/. /home/testssl/bin/
#COPY --chown=testssl:testssl testssl.sh /home/testssl/

#ENTRYPOINT ["certscan.sh"]
CMD ["certscan.sh"]

#CMD ["--help"]