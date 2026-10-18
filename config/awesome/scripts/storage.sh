#!/bin/bash
df -h /sdcard | tail -n 1 | awk '{print $5}' | tr -d '%'
