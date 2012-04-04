#!/bin/bash
#HTML tidy a Google Docs document
#Usage ./gdocstidy.sh doc.htm doc_tidied.htm
tidy -config tidyconfig.cfg -o $2 $1 
