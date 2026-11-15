FROM ubuntu:18.04
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq arduino-core gcc-avr avr-libc make && rm -rf /var/lib/apt/lists/*
WORKDIR /src/Marlin
