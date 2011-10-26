#! /usr/bin/env python
import sys
import os
#import urllib2
#from urlparse import urlparse
#import subprocess
#from Globals import package_home
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
#from lxml import etree
#import magic

XHTML_ENTITIES = os.path.join('www', 'catalog_xhtml', 'catalog.xml')
XHTML2CNXML_XSL = os.path.join('www', 'xhtml2cnxml_meta.xsl')

# HTML Tidy, HTML Soup to XHTML
# Premail XHTML
def tidy_and_premail(content):
    # HTML Tidy
    # Tidy up HTML and convert it to XHTML
    strTidiedXhtml, strErrors = tidy_document(content, options={
        'output-xhtml': 1,     # XHTML instead of HTML4
        'indent': 0,           # Don't use indent which adds extra linespace or linefeeds which are big problems
        'tidy-mark': 0,        # No tidy meta tag in output
        'wrap': 0,             # No wrapping
        'alt-text': '',        # Help ensure validation
        'doctype': 'strict',   # Little sense in transitional for tool-generated markup...
        'force-output': 1,     # May not get what you expect but you will get something
        'numeric-entities': 1, # Remove HTML entities like e.g. nbsp
        'clean': 1,            # Cleaning
        'bare': 1,
        'word-2000': 1,        # Cleans Word HTML
        'drop-proprietary-attributes': 1,
        'enclose-text': 1,     # enclose text in body always with <p>...</p>
        'logical-emphasis': 1  # transforms <i> and <b> text to <em> and <strong> text
        })
    
    # DEBUG
    #f=open('xhtml.xml', 'w')
    #f.write(strTidiedXhtml)
    #f.close

    # XHTML Premailer
	  # Remove CSS references and place the whole CSS inside tags.
	  # BTW: Premailer does this usually for old email clients.
    # Use a special XHTML Premailer which does not destroy the XML structure.
    # If Premailer fails (on complicated CSS) then return the unpremailed tidied HTML
    try:
        premailer = xhtmlPremailer(strTidiedXhtml)
        strTidiedPremailedHtml = premailer.transform()
        return strTidiedPremailedHtml
    except:
        return strTidiedXhtml
    
# Main method. Doing all steps for the HTMLSOUP to CNXML transformation
def xsl_transform(content):
    # 1
    strTidiedHtml = tidy_and_premail(content)

    # 2 Load XHTML catalog files: Makes XHTML entities readable.
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)

    # 3 XSLT transformation
    styleDoc1 = libxml2.parseFile(XHTML2CNXML_XSL)
    style1 = libxslt.parseStylesheetDoc(styleDoc1)
    # doc1 = libxml2.parseFile(afile))
    doc1 = libxml2.parseDoc(strTidiedHtml)
    result1 = style1.applyStylesheet(doc1, None)
    #style1.saveResultToFilename(os.path.join('output', docFilename + '_meta.xml'), result1, 1)
    strResult1 = style1.saveResultToString(result1)
    style1.freeStylesheet()
    doc1.freeDoc()
    result1.freeDoc()

    return strResult1

def htmlsoup_to_cnxml(content):
    content = xsl_transform(content)
    return content

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    print htmlsoup_to_cnxml(content)