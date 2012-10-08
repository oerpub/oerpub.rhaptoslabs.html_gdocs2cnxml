#! /usr/bin/env python
import sys
import os
import urllib2
#from urlparse import urlparse
from urlparse import urljoin
#import subprocess
#from Globals import package_home
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from readability.readability import Document
from functools import partial

current_dir = os.path.dirname(__file__)
XHTML_ENTITIES = os.path.join(current_dir, 'www_html', 'catalog_xhtml', 'catalog.xml')

html_title = 'Untitled'

# HTML Tidy, HTML Soup to XHTML
def tidy2xhtml(html):
    # HTML Tidy
    xhtml, errors = tidy_document(html, options={
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
    # TODO: parse errors from tidy process 
    return xhtml, {}

# Move CSS from stylesheet inside the tags with. BTW: Premailer does this usually for old email clients.
# Use a special XHTML Premailer which does not destroy the XML structure.
def premail(xhtml):
    premailer = xhtmlPremailer(xhtml)
    premailed_xhtml = premailer.transform()
    return premailed_xhtml, {}

# Downloads images from Google Docs and sets metadata for further processing
def download_images(xml):
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
                        image.set('alt', strImageUrl) # getNameFromUrl(strImageUrl))
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

# Initialize libxml2, e.g. transforming XHTML entities to valid XML
def init_libxml2(xml):
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)
    return xml, {}

def xslt(xsl, xml):
    # XSLT transformation with libxml2
    xsl = os.path.join(current_dir, 'www_html', xsl) # TODO: Needs a cleaner solution
    style_doc = libxml2.parseFile(xsl)
    style = libxslt.parseStylesheetDoc(style_doc)
    # doc = libxml2.parseFile(afile)) # another way, just for debugging
    doc = libxml2.parseDoc(xml)
    result = style.applyStylesheet(doc, None)
    # style.saveResultToFilename(os.path.join('output', docFilename + '_xyz.xml'), result, 1) # another way, just for debugging
    xml_result = style.saveResultToString(result)
    style.freeStylesheet()
    doc.freeDoc()
    result.freeDoc()
    
    return xml_result, {}
    
def add_cnxml_title(etree_xml, new_title):
    title = etree_xml.xpath('/cnxml:document/cnxml:title', namespaces={'cnxml':'http://cnx.rice.edu/cnxml'})
    title[0].text = new_title
    return etree_xml
        
# Main method. Doing all steps for the HTMLSOUP to CNXML transformation
def xsl_transform(content, bDownloadImages, base_or_source_url='.'):

    # 1 get title with readability
    html_title = "Untitled"
    try:
        html_title = Document(content).title()
    except:
        pass        
    
    # 2 use readabilty to get content
    readable_article = Document(content).summary()

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

def htmlsoup_to_cnxml_old(content, bDownloadImages=False, base_or_source_url='.'):
    objects = {}
    content, objects, title = xsl_transform(content, bDownloadImages, base_or_source_url)
    return content, objects, title

def get_html_title(content):
    html_title = "Untitled"
    try:
        title = Document(content).title()
    except:
        pass
    return '', {}

# result from every step in pipeline is a string (xml) + object {...}
# explanation of "partial" : http://stackoverflow.com/q/10547659/756056
TRANSFORM_PIPELINE = [
    tidy2xhtml,
    get_html_title,
    partial(xslt, 'pass0_remove_blog_comments.xsl'),
    premail,
    init_libxml2,
    partial(xslt, 'pass1_xhtml_headers.xsl'),
    ]
    
#     partial(xslt, 'pass2_xhtml_gdocs_headers.xsl'),
#     partial(xslt, 'pass3_xhtml_divs.xsl'),
#     partial(xslt, 'pass4_xhtml_text.xsl'),
#     partial(xslt, 'pass6_xhtml2cnxml.xsl'),
#     image_puller,
#     add_cnxml_title,
#     partial(xslt, 'pass7_cnxml_postprocessing.xsl'),
#     partial(xslt, 'pass8_cnxml_id-generation.xsl'),
#     partial(xslt, 'pass9_cnxml_postprocessing.xsl'),
# ]

# the function which is called from outside to start transformation
def htmlsoup_to_cnxml(content, bDownloadImages=False, base_or_source_url='.', debug=False):
    objects = {}
    xml = content

    # write input file to debug dir
    if debug: # create for each pass an output file
        filename = os.path.join(current_dir, 'html_debug', 'input.htm') # TODO: needs a timestamp or something
        f = open(filename, 'w')
        f.write(xml)
        f.flush()
        f.close()    
    for i, transform in enumerate(TRANSFORM_PIPELINE):
        newobjects = {}
        xml, newobjects = transform(xml)
        if len(newobjects) > 0:
            objects.update(newobjects) # copy newobjects into objects dict
        print "== Pass: %02d | Function: %s | Objects: %s ==" % (i+1, transform, objects.keys())
        if debug: # create for each pass an output file
            filename = os.path.join(current_dir, 'html_debug', 'pass%02d.xml' % (i+1)) # TODO: needs a timestamp or something
            f = open(filename, 'w')
            f.write(xml)
            f.flush()
            f.close()
    # write objects to debug dir
    if debug:
        for image_filename, image in objects.iteritems():
            image_filename = os.path.join(current_dir, 'html_debug', image_filename) # TODO: needs a timestamp or something
            image_file = open(image_filename, 'wb') # write binary, important!
            try:
                image_file.write(image)
                image_file.flush()
            finally:
                image_file.close()
    return xml, objects, title

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    print htmlsoup_to_cnxml(content)
