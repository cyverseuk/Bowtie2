FROM ubuntu:16.04

LABEL ubuntu.version="16.04" bowtie.version="2.2.6" maintainer="Alice Minotto, @ Earlham Institute"

USER root

RUN apt-get -y update && apt-get -yy install bowtie2

WORKDIR /data/
