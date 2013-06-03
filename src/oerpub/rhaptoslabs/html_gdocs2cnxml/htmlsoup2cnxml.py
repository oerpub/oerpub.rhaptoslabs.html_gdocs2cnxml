#! /usr/bin/env python
import sys
import os
import urllib2
#from urlparse import urlparse
from urlparse import urljoin
from pkg_resources import resource_filename
#import subprocess
#from Globals import package_home
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from readability.readability import Document

XHTML_ENTITIES = resource_filename('oerpub.rhaptoslabs.html_gdocs2cnxml', 'www_html/catalog_xhtml/catalog.xml')
XHTML2CNXML_XSL1 = resource_filename('oerpub.rhaptoslabs.html_gdocs2cnxml', 'www_html/xhtml2cnxml_meta1.xsl')
XHTML2CNXML_XSL2 = resource_filename('oerpub.rhaptoslabs.html_gdocs2cnxml', 'www_html/xhtml2cnxml_meta2.xsl')

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
def downloadImages(xml, base_or_source_url='.'):
    objects = {}    # image contents will be saved here
    xpathImages = etree.XPath('//cnxtra:image', namespaces={'cnxtra':'http://cnxtra'})
    imageList = xpathImages(xml)
    image_opener = urllib2.build_opener()
    image_opener.addheaders = [('User-agent', 'Mozilla/5.0')]
    for position, image in enumerate(imageList):
        strImageUrl = image.get('src')
        if len(strImageUrl) > 0 and len(base_or_source_url) > 0:
            if base_or_source_url != '.':     # if we have a base url join this url strings
                strImageUrl = urljoin(base_or_source_url, strImageUrl)
            try:
                # strImageContent = urllib2.urlopen(strImageUrl).read() # this does not work for websites like e.g. Wikipedia
                fetch_timeout = 3 # timeout in seconds for trying to get images
                image_request = image_opener.open(strImageUrl, None, fetch_timeout)
                strImageContent = image_request.read()
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
                        image.set('alt', "")
                    image.text = strImageName
                    # add contents of image to object
                    objects[strImageName] = strImageContent

                    # just for debugging
                    #myfile = open(strImageName, "wb")
                    #myfile.write(strImageContent)
                    #myfile.close
            except:
                print 'Warning: ' + strImageUrl + ' could not be downloaded.' # do nothing if url could not be downloaded
        else:
            print 'Warning: image url or base url not valid! One image will be skipped!'
    return xml, objects
    
def add_cnxml_title(etree_xml, new_title):
    title = etree_xml.xpath('/cnxml:document/cnxml:title', namespaces={'cnxml':'http://cnx.rice.edu/cnxml'})
    title[0].text = new_title
    return etree_xml
        
# Main method. Doing all steps for the HTMLSOUP to CNXML transformation
def xsl_transform(content, bDownloadImages, base_or_source_url='.', use_readability=True):

    # 1 get title with readability
    html_title = "Untitled"
    try:
        html_title = Document(content).title()
    except:
        pass        
    
    # 2 use readabilty to get content
    if use_readability:
        readable_article = Document(content).summary()
    else:
        readable_article = content

    # 3 tidy and premail
    strTidiedHtml = tidy_and_premail(readable_article)

    # 4 Load XHTML catalog files: Makes XHTML entities readable.
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)

    # 5 XSLT transformation
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

    # 6 Convert TeX to MathML with Blahtex (not in XHTML)
    # etreeXml = tex2mathml(etreeXml)

    # 7 Optional: Download Google Docs Images
    imageObjects = {}
    if bDownloadImages:
        etreeXml, imageObjects = downloadImages(etreeXml, base_or_source_url)
        
    # 8 add title from html
    etreeXml = add_cnxml_title(etreeXml, html_title)

    # Convert etree back to string
    strXml = etree.tostring(etreeXml) # pretty_print=True)

    # 9 Second transformation
    styleDoc2 = libxml2.parseFile(XHTML2CNXML_XSL2)
    style2 = libxslt.parseStylesheetDoc(styleDoc2)
    doc2 = libxml2.parseDoc(strXml)
    result2 = style2.applyStylesheet(doc2, None)
    #style2.saveResultToFilename('tempresult.xml', result2, 0) # just for debugging
    strResult2 = style2.saveResultToString(result2)
    style2.freeStylesheet()
    doc2.freeDoc()
    result2.freeDoc()
    
    return strResult2, imageObjects, html_title    

def htmlsoup_to_cnxml(content, bDownloadImages=False, base_or_source_url='.'):
    objects = {}
    content, objects, title = xsl_transform(content, bDownloadImages, base_or_source_url)
    return content, objects, title

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    print aloha_htmlsoup_to_cnxml(content)
