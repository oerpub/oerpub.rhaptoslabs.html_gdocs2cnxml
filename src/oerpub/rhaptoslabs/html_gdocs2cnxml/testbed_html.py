'''
Testing and development of HTML to CNXML transformation.

Transforms all HTML files in testbed folder to CNXML.
Validates the result with Jing Relax NG.

Input is any file matching the TESTBED_INPUT_FILEEXT.
CNXML results are saved as .xml in TESTBED_OUTPUT_DIR.

Jing Relax NG validation results are saved as .log in TESTBED_OUTPUT_DIR.
If there is no error during validation the .log file has zero bytes.

Created on 13.09.2011

@author: Marvin Reimer
'''

import sys
import glob
import os
import subprocess
from htmlsoup2cnxml import htmlsoup_to_cnxml

TESTBED_INPUT_DIR = "testbed_html"  # the testbed folder
TESTBED_INPUT_FILEEXT = "*.htm*"
TESTBED_OUTPUT_DIR = "testbed_html_output"

# tests if java is installed and available at commandline
def java_installed():
    error = True
    try:
        p = subprocess.Popen('java -version', shell=True, stdout=subprocess.PIPE)
        error = p.communicate()[1]
    finally:
        return not error

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
    print_status('Validating %s ...' % xml_filename)
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

# converts all matching files in testbed input folder to CNXML output folder
def main():
    # Keep sure Java is installed (needed for Jing)
    if not java_installed():
        print "ERROR: Could not find Java. Please keep sure that Java is installed and available."
        exit(1)
    for html_filename in glob.glob(os.path.join(TESTBED_INPUT_DIR, TESTBED_INPUT_FILEEXT)):
        # output filename string preparation
        just_filename = os.path.basename(html_filename)
        just_filename_no_ext = os.path.splitext(just_filename)[0]
        cnxml_filename = os.path.join(TESTBED_OUTPUT_DIR, just_filename_no_ext + '.xml')
        jing_log_filename= os.path.join(TESTBED_OUTPUT_DIR, just_filename_no_ext + '.log')

        # read HTML testbed files
        html_file = open(html_filename)
        html = html_file.read()

        print_status('Transforming %s ...' % just_filename)

        # transform
        cnxml,objects = htmlsoup_to_cnxml(html, bDownloadImages=True)
        
        # write testbed images
        for image_filename, image in objects.iteritems():
            image_filename = os.path.join(TESTBED_OUTPUT_DIR, image_filename)
            image_file = open(image_filename, 'wb') # write binary, important!
            try:
                image_file.write(image)
                image_file.flush()
            finally:
                image_file.close()        

        # write testbed CNXML output
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
            print_status('Validating...')
            jing_validate_file(cnxml_filename, jing_log_filename)       

    print_status('Finished!')

if __name__ == "__main__":
    main()
