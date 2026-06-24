############################################################################

#File: nested_batchImportPrep.py
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
#json
#csv
#numpy

#Data File Inputs:
#The script calls for a path to be an argument. The path should contain all folders and subfolders that should be tarred. 

#Outputs:
#The script will create tar files of subfolders.
 
#To run script, you will need to do the following command:
#python3 nested_batchImportPrep.py ./FolderOfInterest
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
#import pandas
import json
import csv



# need to untar the base dataset folder
#argv[1] = directory of interest that script should be run in. 


topDir = Path(argv[1])
#metadata = csv.reader(Path(argv[2]))

def list_visible_files_with_pathlib_iterdir(directory):
    path_object = Path(directory)
    visible_files = [item.name for item in path_object.iterdir() if not item.name.startswith('.')]
    return visible_files

def remove_hidden_unix(path):
    for filename in os.listdir(path):
        if filename.startswith('.'):
            filepath = os.path.join(path, filename)
            if os.path.isfile(filepath):
                os.remove(filepath)
                print(f"Removed: {filepath}")
            elif os.path.isdir(filepath):
                os.rmdir(filepath)
                print(f"Removed directory: {filepath}")

def tarAndRemove(dataTarFolder):
    print(dataTarFolder)
    selected_files = list(dataTarFolder.glob('*.*'))
    print(selected_files)
    for archive in selected_files:
        shutil.unpack_archive(filename=archive, extract_dir=topDir) #untar folders
        print(archive)
        os.remove(archive)
    

        

def tarSubFolders(fname):
     
    visible_files = list_visible_files_with_pathlib_iterdir(fname)
    print(visible_files)
    selected_files = []
    for folder in visible_files:
        if folder.endswith('tar'):
            print(folder, 'is a tar file')
        elif folder.startswith('.'):
            print(folder, 'is a hidden file')
        else:    
            selected_files.append(folder)
    
    for folderName in selected_files:
        files = os.path.join(fname, folderName)
        print(files)
        shutil.make_archive(files, 'tar', files)



tarAndRemove(topDir)
remove_hidden_unix(topDir)
fileList = os.listdir(topDir)
print(fileList)
for dataFolder in fileList:
    remove_hidden_unix(topDir)
    folder = os.path.join(topDir, dataFolder)    
    tarSubFolders(Path(folder))
    remove_hidden_unix(Path(folder))

