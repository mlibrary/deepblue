############################################################################

#File: createYaml.py
#Code Creator: Peter Cerda
#Contact: pacerda@umich.edu
#Date executed: 2026-06-24

#Operating System (and version as well as bit number if appropriate) executed on: Linux

 
#Software Version: Python 3

#Python Libraries/Dependencies:
#pathlib
#os
#sys
#datetime
#glob
#fnmatch
#re
#shutil
#pandas
#json
#csv
#numpy

#Data File Inputs:
#metadata spreadsheet

#Outputs:
#yml files named after each dataset.


#Description: This script will read the metadata speadsheet and will assign metadata to the approprate dataset ingest file. It will also explore the folder named in the metadata to identify folder and files paths.
 

###########################################################################



#import these libraries from the other script will prune as needed

from pathlib import Path

import os
from sys import argv
# import idigbio
import datetime
import glob
import fnmatch
import re
# from pygbif import occurrences as occ
import shutil
import pandas as pd
import json
import csv
import numpy


now = datetime.datetime.now()
df = pd.read_csv(argv[1])
#df = pd.read_csv('../dbDataMeta.csv')


def createyml(fname):
    print("fname: " + fname)

    ownEmail = df['authoremail'].iloc[row] #Author Email from CSV
    ownauth = df['owner'].iloc[row] #owner name from CSV
    
    ytop = ("---\n:user:\n  :visibility: open\n  :state: active\n  :email: '%s'\n  :ingester: 'fritx@umich.edu'\n  :source: DBDv2\n  :mode: build\n  :works:\n    :depositor: 'pacerda@umich.edu'\n" % (ownEmail))
    
    yownauth = ("    :owner: '%s'\n    :authoremail: '%s'\n" % (ownauth, ownEmail))

    
    ytitle = ("    :title: \n      - '%s' \n" % (df['title'].iloc[row]))#pull from csv 


    ydate = ("    :date_uploaded:\n      - '%s'\n" % (now.year))

    yrefby = ("    :referenced_by:\n      - '%s'\n" % df['referenced_by'].iloc[row])
                    
    ymethod =("    :methodology:\n      - '%s'\n" % df['methodology'].iloc[row])
    
    ypartof = ("    :part_of:\n      - 'is part of %s'\n" % df['referenced_by'].iloc[row])
    
    ycrea = df['creator'].iloc[row]
    ycreat = ycrea.split(';')
    ycreator = ("    :creator: \n      - %s\n" % (            '\n      - '.join("'{0}'".format(w) for w in ycreat)))

    kw = df['keyword'].iloc[row]
    kws = kw.split(';')
    ykw = ("    :keyword: \n      - %s\n" % (            '\n      - '.join("'{0}'".format(w) for w in kws)))

    yrights = ("    :rights_license:\n      - '%s'\n" % df['rights_license'].iloc[row])

    yrightsOther = ("   :rights_license_other:\n.     - '%s'\n" % df['rights_license_other'].iloc[row])
    
    ydatecov = ("    :date_coverage:\n      - '%s'\n" % df['date_coverage'].iloc[row]) 

    ysub = df['subject_discipline'].iloc[row]
    ysubj = ysub.split(';')
    ysubject = ("    :subject_discipline:\n      - %s\n" % (            '\n      - '.join("'{0}'".format(w) for w in ysubj)))

    # ybib = ("    :bibliographic_citation:\n      - 'For more information on the original UMMZ specimen, see: https://www.gbif.org/occurrence/%s'\n" % (ummzdict['yuuid'])) #build URL from iDigBio uuid

    ydesclist = ("    :description:\n      - '%s'\n" % df['description'].iloc[row])

    ylang = ("    :language:\n      - '%s'\n" % df['language'].iloc[row])
    
    ycurnote = ("    :curation_notes_admin:\n      - %s\n" % df['curation_notes_admin'].iloc[row])
    
    ydoi = ("    :doi: 'mint_now'\n")
    
    ycoll = ("    :in_collections:\n      - %s \n" % df['in_collections'].iloc[row]) #pull from csv


    #get file listing from folders noted in metadata
    serverPath = '/deepbluedata-prep-new/upload-globus/UMMAA/ComVert'
    uf = ""
    ixPath = ""
    if df['packaged'].iloc[row] == 'yes':
        folder_path = Path(df['Folder'].iloc[row])
        for item in folder_path.iterdir():
            if item.name.endswith('.tar') == True:
                uf = uf + (("      - %s\n" % (item.name)))
                ixPath = ixPath + (("      - %s/%s/%s\n" % (serverPath,folder_path, item.name) ))
                print(uf)
                print(ixPath)

    else:
        folder_path = Path(df['Folder'].iloc[row])
        for item in folder_path.iterdir():
            uf = uf + (("      - %s\n" % (item.name)))
            ixPath = ixPath + (("      - %s/%s/%s\n" % (serverPath, folder_path, item) ))
            print(uf)
            print(ixPath)
    # UMMZ usage agreement file


    yfilename = ("    :filenames:\n%s\n      - README_UMMAA_Photogrammetric_Datasets.txt\n      - UMMAA_Digital_Data_Usage_Terms_and_Conditions.pdf\n" % (uf))  # pull from directory
    yfiles = ("    :files:\n%s\n      - /deepbluedata-prep-new/upload-globus/UMMAA/ComVert/README_UMMAA_Photogrammetric_Datasets.txt\n      - /deepbluedata-prep-new/upload-globus/UMMAA/ComVert/UMMAA_Digital_Data_Usage_Terms_and_Conditions.pdf\n" % (ixPath))  # pull from directory


    file_name = '%s.yml' % (df['Folder'].iloc[row])
    f = open(file_name, 'w')  # open file in write mode

    f.write(ytop)
    f.write(ycoll)
    f.write(yownauth)
    f.write(ycreator)
    f.write(ytitle)
    # f.write(ydate)
    f.write(yrefby)
    f.write(ymethod)
    f.write(ykw)
    # for desc in ummzdict['desc']:
    f.write(ydesclist)
    f.write(yrights)
    f.write(ydatecov)
    f.write(ysubject)
    # f.write(ybib)
    f.write(ylang)
    f.write(ycurnote)
    f.write(ydoi)
    f.write(yfilename)
    f.write(yfiles)
    #    f.write(yUAFilename)
    #    f.write(yUAFiles)

    f.close()
    return


for row in df.index:
    print(row)
    createyml(df.iloc[row])
    print("YAML files created")
