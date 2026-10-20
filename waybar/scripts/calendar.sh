#!/bin/bash
# Use watch to keep the window open. 
# -c preserves colors, -t hides the title/refresh timer.
watch -c -t -n 60 'cal --year --week --color=always'
