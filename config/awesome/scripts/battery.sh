#!/bin/bash
# Gets the battery percentage
termux-battery-status | jq '.percentage'
