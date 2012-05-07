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

current_dir = os.path.dirname(__file__)

# Should all steps in between written to output/disk
DEBUG_MODE = True

XHTML_ENTITIES = os.path.join(current_dir, 'www', 'catalog_xhtml', 'catalog.xml')

# All steps in between are string steps
TRANSFORM_PIPELINE = [
    tidy_and_premail,
#    xhtml_xslt('pass1_gdocs_headers.xsl'),
#    xhtml_xslt('pass2_xhtml_gdocs_headers.xsl'),
#    xhtml_xslt('pass3_gdocs_listings.xsl'),
#    xhtml_xslt('pass4_gdocs_listings.xsl'),
#    xhtml_xslt('pass5_gdocs_listings.xsl'),
#    xhtml_xslt('pass5_part2_gdocs_red2cnxml.xsl'),
#    xhtml_xslt('pass6_gdocs2cnxml.xsl'),
#    tex2mathml_transform,
#    image_puller,
#    xslt('pass7_cnxml_postprocessing.xsl'),
#    xslt('pass8_cnxml_id-generation.xsl'),
#    xslt('pass9_cnxml_postprocessing.xsl'),
]

# Tidy up the Google Docs HTML Soup
def tidy_and_premail(content):
    # HTML Tidy
    tidied_html, errors = tidy_document(content, options={
        'output-xhtml': 1,     # XHTML instead of HTML4
        'indent': 0,           # Don't use indent, add's extra linespace or linefeeds which are big problems
        'tidy-mark': 0,        # No tidy meta tag in output
        'wrap': 0,             # No wrapping
        'alt-text': '',        # Help ensure validation
        'doctype': 'strict',   # Little sense in transitional for tool-generated markup...
        'force-output': 1,     # May not get what you expect but you will get something
        'numeric-entities': 1, # remove HTML entities like e.g. nbsp
        'clean': 1,            # remove
        'bare': 1,
        'word-2000': 1,
        'drop-proprietary-attributes': 1,
        'enclose-text': 1,     # enclose text in body always with <p>...</p>
        'logical-emphasis': 1  # transforms <i> and <b> text to <em> and <strong> text
        })

	# Move CSS from stylesheet inside the tags with. BTW: Premailer does this usually for old email clients.
    # Use a special XHTML Premailer which does not destroy the XML structure.
    premailer = xhtmlPremailer(tidied_html)
    tidied_premailed_html = premailer.transform()
    return tidied_premailed_html

# Use Blahtex transformation from TeX to XML. http://gva.noekeon.org/blahtexml/
def tex2mathml(xml):
    # Do not run blahtex if we are not on Linux!
    if os.name == 'posix':
        xpathFormulars = etree.XPath('//cnxtra:tex[@tex]', namespaces={'cnxtra':'http://cnxtra'})
        formularList = xpathFormulars(xml)
        for formular in formularList:
            strTex = urllib2.unquote(formular.get('tex'))
            #TODO: Ubuntu has 'blahtexml', when compiled by yourself the binary name will be 'blahtex'. This needs to be more dynamically!
            strCmdBlahtex = ['blahtexml','--mathml']
            # run the program with subprocess and pipe the input and output to variables
            p = subprocess.Popen(strCmdBlahtex, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            #TODO: Catch blahtex processing errors!
            strMathMl, strErr = p.communicate(strTex) # set STDIN and STDOUT and wait till the program finishes
            mathMl = etree.fromstring(strMathMl)
            formular.append(mathMl)
    else:
        print 'Error: Math will not be converted! Blahtex is only available on Linux!'
    return xml

# Get the filename without extension form a URL
# TODO: This does not worked reliable
# def getNameFromUrl(s):
#     return os.path.splitext(urllib2.unquote(os.path.basename(urlparse(s).path)))[0]

# Downloads images from Google Docs and sets metadata for further processing
def downloadImages(xml):
    objects = {}    # image contents will be saved here
    xpathImages = etree.XPath('//cnxtra:image', namespaces={'cnxtra':'http://cnxtra'})
    imageList = xpathImages(xml)
    for position, image in enumerate(imageList):
        strImageUrl = image.get('src')
        print "Download GDoc Image: " + strImageUrl  # Debugging output
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
            #Note: SVG is currently (2012-03-08) not supported by GDocs.
            strAlt = image.get('alt')
            if not strAlt:
                image.set('alt', strImageUrl) # getNameFromUrl(strImageUrl)) # TODO: getNameFromUrl does not work reliable
            image.text = strImageName
            # add contents of image to object
            objects[strImageName] = strImageContent

            # just for debugging
            #myfile = open(strImageName, "wb")
            #myfile.write(strImageContent)
            #myfile.close
    return xml, objects

# Main method. Doing all steps for the Google Docs to CNXML transformation
def xsl_transform(content, bDownloadImages):
    # 1
    strTidiedHtml = tidy_and_premail(content)

    # 2 Settings for libxml2 for transforming XHTML entities  to valid XML
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)

    # 3 First XSLT transformation
    styleDoc1 = libxml2.parseFile(GDOCS2CNXML_XSL1)
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

    # 4 Convert TeX to MathML with Blahtex
    etreeXml = tex2mathml(etreeXml)

    # 5 Optional: Download Google Docs Images
    imageObjects = {}
    if bDownloadImages:
        etreeXml, imageObjects = downloadImages(etreeXml)

    # Convert etree back to string
    strXml = etree.tostring(etreeXml) # pretty_print=True)

    # 6 Second transformation
    styleDoc2 = libxml2.parseFile(GDOCS2CNXML_XSL2)
    style2 = libxslt.parseStylesheetDoc(styleDoc2)
    doc2 = libxml2.parseDoc(strXml)
    result2 = style2.applyStylesheet(doc2, None)
    #style2.saveResultToFilename('tempresult.xml', result2, 0) # just for debugging
    strResult2 = style2.saveResultToString(result2)
    style2.freeStylesheet()
    doc2.freeDoc()
    result2.freeDoc()

    return strResult2, imageObjects
    
def gdocs_new_transform(content, bDownloadImages):
    result = ""
    images = {}
    
    return result, images

# the function which is called from outside to start transformation
def gdocs_to_cnxml(content, bDownloadImages=False):
    objects = {}
    #content, objects = gdocs_transform(content, bDownloadImages)
    content, objects = gdocs_new_transform(content, bDownloadImages)
    return content, objects

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    print gdocs_to_cnxml(content)
