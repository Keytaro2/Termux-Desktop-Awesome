#!/bin/bash
uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | awk '{usage=$1*12.5; if(usage>100) print 100; else print usage}'
