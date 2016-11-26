#!/usr/bin/env python

import boto.s3
from boto.s3.key import Key
import argparse
import ruamel.yaml
from ruamel.yaml.util import load_yaml_guess_indent
import re

URI = "https://s3.amazonaws.com/labsdeps/"
LEPTONICA_FILE = "../bin/steps/leptonica"
OPENCV_FILE = "../bin/steps/opencv"
TESSERACT_FILE = "../bin/steps/tesseract"
TESSDATA_FILE = "../bin/steps/tessdata"
GHOSTSCRIPT_FILE = "../bin/steps/ghostscript"
PYTHON_GS_FILE = "../bin/steps/gs"

class Update(object):

    TXT_FILE="sift-dependencies-md5.txt"
    
    MANIFEST_FILE="../manifest.yml"

    def upload_to_s3(self,accesskey, secretkey, bucketname):
        with open(self.TXT_FILE) as f:
            for line in f:
                if (len(line)>4):
                    s = line.split(" ")
                    md5 = s[0].rstrip()
                    filename = s[2].rstrip()
                    print ("Uploading: " + filename)
                    try:
                        if (filename.index("leptonica")>=0):
                            self.leptonica_file_name = filename
                            self.leptonica_md5 = md5
                    except:
                        pass
                    try:
                        if (filename.index("opencv")>=0):
                            self.opencv_file_name = filename
                            self.opencv_md5 = md5
                    except:
                        pass
                    try:
                        if (filename.index("gs9_2")>=0):
                            self.ghostscript_file_name = filename
                            self.ghostscript_md5 = md5
                    except:
                        pass
                    try:
                        if (filename.index("tesseract")>=0):
                            self.tesseract_file_name = filename
                            self.tesseract_md5 = md5
                    except:
                        pass
                    try:
                        if (filename.index("tessdata")>=0):
                            self.tessdata_file_name = filename
                            self.tessdata_md5 = md5
                    except:
                        pass
                    try:
                        if (filename.index("python-gs")>=0):
                            self.gs_file_name = filename
                            self.gs_md5 = md5
                    except:
                        pass
                    conn = boto.connect_s3(accesskey, secretkey)
                    bucket = conn.get_bucket(bucketname)
                    key = bucket.new_key(filename)
                    key.set_contents_from_filename(filename)

    def update_manifest(self):
        print "Updating manifest"
        config, ind, bsi = load_yaml_guess_indent(open(self.MANIFEST_FILE))
        dependencies = config['dependencies']
        for dep in dependencies:

            if dep['name'] in ["leptonica","tesseract","opencv","gs9", "python-gs","tessdata"]:
                try:
                    if (dep['name'] =="leptonica"):
                        dep['uri'] = URI+self.leptonica_file_name
                        dep['md5'] = self.leptonica_md5
                    elif (dep['name'] == "opencv"):
                        dep['uri'] = URI+self.opencv_file_name
                        dep['md5'] = self.opencv_md5
                    elif (dep['name'] == "gs9"):
                        dep['uri'] = URI+self.ghostscript_file_name
                        dep['md5'] = self.ghostscript_md5
                    elif (dep['name'] == "tesseract"):
                        dep['uri'] = URI+self.tesseract_file_name
                        dep['md5'] = self.tesseract_md5
                    elif (dep['name'] == "tessdata"):
                        dep['uri'] = URI+self.tessdata_file_name
                        dep['md5'] = self.tessdata_md5
                    elif (dep['name'] == "python-gs"):
                        dep['uri'] = URI+self.gs_file_name
                        dep['md5'] = self.gs_md5
                except:
                    pass
        ruamel.yaml.round_trip_dump(config, open(self.MANIFEST_FILE, 'w'), 
                                indent=ind, block_seq_indent=bsi)

    def inplace_change(self,filename, old_string, new_string):
        regexp = re.compile(old_string)
        with open(filename) as f:
            s = f.read()
            # if old_string not in s:
            if regexp.search(s) is None:
                print '"{old_string}" not found in {filename}.'.format(**locals())
                return

        # Safely write the changed content, if found in the file
        with open(filename, 'w') as f:
            print 'Changing "{old_string}" to "{new_string}" in {filename}'.format(**locals())
            # s = s.replace(old_string, new_string)
            s = re.sub(old_string, new_string, s)
            f.write(s)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='pre-process and ocr image')

    
    parser.add_argument('--access-key', dest='accesskey')
    parser.add_argument('--secret-key', dest='secretkey')
    parser.add_argument('--bucket-name', dest='bucketname')

    options = parser.parse_args()

    u = Update()
    u.upload_to_s3(options.accesskey, options.secretkey, options.bucketname)
    u.update_manifest()
    u.inplace_change(LEPTONICA_FILE,'VENDORED_LEPTONICA="(.*)"','VENDORED_LEPTONICA="'+ URI+u.leptonica_file_name+'"')
    u.inplace_change(OPENCV_FILE,'VENDORED_OPENCV="(.*)"','VENDORED_OPENCV="'+ URI+u.opencv_file_name+'"')
    u.inplace_change(TESSERACT_FILE,'VENDORED_TESS="(.*)"','VENDORED_TESS="'+ URI+u.tesseract_file_name+'"')
    u.inplace_change(TESSDATA_FILE,'VENDORED_TESSDATA="(.*)"','VENDORED_TESSDATA="'+ URI+u.tessdata_file_name+'"')
    u.inplace_change(GHOSTSCRIPT_FILE,'VENDORED_GHOSTSCRIPT="(.*)"','VENDORED_GHOSTSCRIPT="'+ URI+u.ghostscript_file_name+'"')
    u.inplace_change(PYTHON_GS_FILE,'VENDORED_PYTHON_GS="(.*)"','VENDORED_PYTHON_GS="'+ URI+u.gs_file_name+'"')

