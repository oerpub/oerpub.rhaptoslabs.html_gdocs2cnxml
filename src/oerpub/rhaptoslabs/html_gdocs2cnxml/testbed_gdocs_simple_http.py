'''
Testing and development of GDocs to CNXML transformation.

Transforms all GDocs URLs in testbed folder to CNXML.
Validates the result with Jing Relax NG.

Input are all URLs in TESTBED_INPUT_URLS_FILE.

CNXML results are saved as in a directory named like the GDocs ID as:
  .xml             -  the CNXML result
  .htm             -  the raw HTML GDocs input format before transformation
  .png/.jpg/.gif   -  including all images
  .log             -  Jing Relax NG validation results

 If there is no error during validation the .log file has zero bytes.

Created on 14.09.2011

@author: Marvin Reimer
'''

import sys
import os
import subprocess
import re
import shutil
import httplib2
from gdocs2cnxml import gdocs_to_cnxml

TESTBED_INPUT_DIR = "testbed_gdocs"  # the testbed folder
TESTBED_INPUT_URLS_FILE = "testbed_gdocs_urls.cfg"
TESTBED_OUTPUT_DIR = "testbed_gdocs_output"

# tests if java is installed and available at commandline
def java_installed():
    error = True
    try:
        p = subprocess.Popen('java -version', shell=True, stdout=subprocess.PIPE)
        error = p.communicate()[1]
    finally:
        return not error

# Be careful with this command!
def delete_all_contents_of_folder(folder):
    if os.path.isdir(folder):
        for root, dirs, files in os.walk(folder):
            for f in files:
                os.unlink(os.path.join(root, f))
            for d in dirs:
                shutil.rmtree(os.path.join(root, d))

# prints a status message surrounded by some lines
def print_status(status_message):
    print '=' * 79
    print status_message
    print '=' * 79

# Jing validation and save log file
def jing_validate_file(xml_filename, log_filename):
    # build the java commandline string
    jing_jar_filename = os.path.join('jing', 'jing.jar')
    jing_rng_filename = os.path.join('jing', 'cnxml-jing.rng')
    java_cmd = 'java -jar %s %s %s' % (jing_jar_filename, jing_rng_filename, xml_filename)
    # validate XML and save log file
    jing_log_file = open(log_filename, 'w')
    try:
        p = subprocess.Popen(java_cmd, shell=True, stdout=subprocess.PIPE)
        jing_log, error_data = p.communicate()
        if not error_data:
            jing_log_file.write(jing_log)
        else:
            jing_log_file.write(error_data)
    finally:
        jing_log_file.close()

# converts all URLs in testbed input file to CNXML output folder
def main():
    # keep sure Java is installed (needed for Jing)
    if not java_installed():
        print "ERROR: Could not find Java. Please keep sure that Java is installed and available."
        exit(1)
    # delete the contents of the testbed folder
    delete_all_contents_of_folder(TESTBED_OUTPUT_DIR)
    # open file with GDocs public documents URLs (<- the testbed for GDocs)
    url_file = open(os.path.join(TESTBED_INPUT_DIR, TESTBED_INPUT_URLS_FILE))
    for url in url_file:
        if not url.startswith('#'):   # ignore comments
            # check if we really have a gdocs document with an ID
            # Get the ID out of the URL with regular expression
            match_doc_id = re.match(r'^.*docs\.google\.com/document/d/([^/]+).*$', url)
            if match_doc_id:
                doc_id = match_doc_id.group(1)

                # create a sub directory named like the ID
                doc_output_dir = os.path.join(TESTBED_OUTPUT_DIR, doc_id)
                try:
                    os.mkdir(doc_output_dir)
                except OSError:
                    pass    # If subdirectory already exists do nothing

                doc_key = 'document:' +  doc_id

                print_status('Getting ' + doc_key)

                # get the Google Docs by fetching the HTML directly

                http = httplib2.Http()
                http.follow_redirects = False
                try:
                    plain_html_url = 'https://docs.google.com/document/d/%s/export?format=html&confirm=no_antivirus' % doc_id
                    print_status('URL: ' + plain_html_url)
                    resp, html = http.request(plain_html_url)
                except HttpError:
                    print "Error: Failed to download Google Docs HTML"
                try:
                    kix_url = 'https://docs.google.com/feeds/download/documents/export/Export?id=%s&exportFormat=kix' % doc_id
                    print_status('URL: ' + kix_url)
                    resp, kix = http.request(kix_url)
                except HttpError:
                    print "Error: Failed to download Google Docs Kix"


                # write testbed source html output
                html_filename = os.path.join(doc_output_dir, doc_id +'.htm')
                html_file = open(html_filename, 'w')
                try:
                    html_file.write(html)
                    html_file.flush()
                finally:
                    html_file.close()

                print_status('Transforming and get images from %s' % doc_key)

                # transformation and get images
                cnxml, objects = gdocs_to_cnxml(html, kixcontent=kix, bDownloadImages=True)

                # write testbed images
                for image_filename, image in objects.iteritems():
                    image_filename = os.path.join(doc_output_dir, image_filename)
                    image_file = open(image_filename, 'wb') # write binary, important!
                    try:
                        image_file.write(image)
                        image_file.flush()
                    finally:
                        image_file.close()

                # write testbed CNXML output
                cnxml_filename = os.path.join(doc_output_dir, doc_id + '.xml')
                cnxml_file = open(cnxml_filename, 'w')
                try:
                    cnxml_file.write(cnxml)
                    cnxml_file.flush()
                finally:
                    cnxml_file.close()

                # validate CNXML output with Jing Relax NG
                if len(sys.argv) > 1 and sys.argv[1] == '-noval':
                    print_status('Validation skipped')
                else:
                    print_status('Validating %s' % doc_key)
                    jing_log_filename = os.path.join(doc_output_dir, doc_id + '.log')
                    jing_validate_file(cnxml_filename, jing_log_filename)

    print_status('Finished!!!')

if __name__ == "__main__":
    main()
