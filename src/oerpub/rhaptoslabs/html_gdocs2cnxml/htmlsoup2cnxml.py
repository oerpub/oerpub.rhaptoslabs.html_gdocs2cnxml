#! /usr/bin/env python
import sys
import os
import urllib2
#from urlparse import urlparse
#import subprocess
#from Globals import package_home
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from readability.readability import Document

current_dir = os.path.dirname(__file__)
XHTML_ENTITIES = os.path.join(current_dir, 'www', 'catalog_xhtml', 'catalog.xml')
XHTML2CNXML_XSL1 = os.path.join(current_dir, 'www', 'xhtml2cnxml_meta1.xsl')
XHTML2CNXML_XSL2 = os.path.join(current_dir, 'www', 'xhtml2cnxml_meta2.xsl')

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

# Downloads images and sets metadata for further processing
def downloadImages(xml):
    objects = {}    # image contents will be saved here
    xpathImages = etree.XPath('//cnxtra:image', namespaces={'cnxtra':'http://cnxtra'})
    imageList = xpathImages(xml)
    for position, image in enumerate(imageList):
        strImageUrl = image.get('src')
        try:
            strImageContent = urllib2.urlopen(strImageUrl).read()
            # get Mime type from image
            strImageMime = magic.whatis(strImageContent)
            # only allow this three image formats
            if strImageMime in ('image/png', 'image/jpeg', 'image/gif'):
                image.set('mime-type', strImageMime)
                strImageName = "gd-%04d" % (position + 1)  # gd0001.jpg
                if strImageMime == 'image/jpeg':
                    strImageName += '.jpg'
                elif strImageMime == 'image/png':
                    strImageName += '.png'
                elif strImageMime == 'image/gif':
                    strImageName += '.gif'
                strAlt = image.get('alt')
                if not strAlt:
                    image.set('alt', strImageUrl) # getNameFromUrl(strImageUrl))
                image.text = strImageName
                # add contents of image to object
                objects[strImageName] = strImageContent

                # just for debugging
                #myfile = open(strImageName, "wb")
                #myfile.write(strImageContent)
                #myfile.close
        except urllib2.HTTPError, e:
            print 'Warning: ' + strImageUrl + 'could not be downloaded.' # do nothing if url could not be downloaded
    return xml, objects
        
# Main method. Doing all steps for the HTMLSOUP to CNXML transformation
def xsl_transform(content, bDownloadImages):

    # 1 use readability
    readable_article = Document(content).summary()

    # 2 tidy and premail
    strTidiedHtml = tidy_and_premail(readable_article)

    # 3 Load XHTML catalog files: Makes XHTML entities readable.
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)

    # 4 XSLT transformation
    styleDoc1 = libxml2.parseFile(XHTML2CNXML_XSL1)
    style1 = libxslt.parseStylesheetDoc(styleDoc1)
    # doc1 = libxml2.parseFile(afile))
    doc1 = libxml2.parseDoc(strTidiedHtml)
    result1 = style1.applyStylesheet(doc1, None)
    #style1.saveResultToFilename(os.path.join('output', docFilename + '_meta.xml'), result1, 1)
    strResult1 = style1.saveResultToString(result1)
    style1.freeStylesheet()
    doc1.freeDoc()
    result1.freeDoc()

    # Parse XML with etree from lxml for TeX2MathML and image download
    etreeXml = etree.fromstring(strResult1)

    # 5 Convert TeX to MathML with Blahtex (not in XHTML)
    # etreeXml = tex2mathml(etreeXml)

    # 6 Optional: Download Google Docs Images
    imageObjects = {}
    if bDownloadImages:
        etreeXml, imageObjects = downloadImages(etreeXml)

    # Convert etree back to string
    strXml = etree.tostring(etreeXml) # pretty_print=True)

    # 7 Second transformation
    styleDoc2 = libxml2.parseFile(XHTML2CNXML_XSL2)
    style2 = libxslt.parseStylesheetDoc(styleDoc2)
    doc2 = libxml2.parseDoc(strXml)
    result2 = style2.applyStylesheet(doc2, None)
    #style2.saveResultToFilename('tempresult.xml', result2, 0) # just for debugging
    strResult2 = style2.saveResultToString(result2)
    style2.freeStylesheet()
    doc2.freeDoc()
    result2.freeDoc()

    return strResult2, imageObjects

def htmlsoup_to_cnxml(content, bDownloadImages=False):
    objects = {}
    content, objects = xsl_transform(content, bDownloadImages)
    return content, objects

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    print htmlsoup_to_cnxml(content)
