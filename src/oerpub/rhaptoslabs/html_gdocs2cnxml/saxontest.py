#! /usr/bin/env python
import sys
import os
import urllib2
#from urlparse import urlparse
import subprocess
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from functools import partial

current_dir = os.path.dirname(__file__)

XHTML_ENTITIES = os.path.join(current_dir, 'www_gdocs', 'catalog_xhtml', 'catalog.xml')

# XSLT 2.0 transformation with Saxon-B
def xslt2(xsl, xml):
    xsl = os.path.join(current_dir, 'www_gdocs', xsl)
    cmd_saxon = ['saxonb-xslt','-- todo....']
    # run the program with subprocess and pipe the input and output to variables
    p = subprocess.Popen(cmd_saxon-b, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    #TODO: Catch Saxon-B processing errors
    console, error = p.communicate(strTex) # set STDIN and STDOUT and wait till the program finishes
    output = ''
    return output

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    #print gdocs_to_cnxml(content)
    gdocs_to_cnxml(content, bDownloadImages=True, debug=True)