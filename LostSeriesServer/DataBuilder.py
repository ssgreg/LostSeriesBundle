# -*- coding: utf-8 -*-
# 
# DataBuilder.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import os
import shutil
import logging.config
import ConfigParser
import codecs
import Image


import lf_parser
import Tools
from Storage import *



DATA_DIRECTORY = "LoadSeriesData1"
SHOW_DIRECTORY_FORMAT = 'TVShow="{0}"'
ARTWORK_DIRECTORY = "LostSeriesArtworks"


class UnicodeConfigParser(ConfigParser.RawConfigParser):

    def __init__(self, defaults=None, dict_type=dict):
        ConfigParser.RawConfigParser.__init__(self, defaults, dict_type)
       
    def write(self, fp):
        """Fixed for Unicode output"""
        if self._defaults:
            fp.write("[%s]\n" % DEFAULTSECT)
            for (key, value) in self._defaults.items():
                fp.write("%s = %s\n" % (key, unicode(value).replace('\n', '\n\t')))
            fp.write("\n")
        for section in self._sections:
            fp.write("[%s]\n" % section)
            for (key, value) in self._sections[section].items():
                if key != "__name__":
                    fp.write("%s = %s\n" %
                             (key, unicode(value).replace('\n','\n\t')))
            fp.write("\n")

    # This function is needed to override default lower-case conversion
    # of the parameter's names. They will be saved 'as is'.
    def optionxform(self, strOut):
        return strOut


def MakeShowDirectoryName(showOriginalName):
  return SHOW_DIRECTORY_FORMAT.format(showOriginalName)


def MakeThumbnail(src, dst):
  size = 188, 188
  im = Image.open(src)
  im = im.resize((188, 188), Image.ANTIALIAS)
  im.save(dst, "JPEG", quality=90)



logging.config.fileConfig('logging.ini')

showsAll = lf_parser.LoadInfoAllShows()
episodesLast = lf_parser.LoadInfoLastSeries(3)

showsIDToOriginalName = dict((i[lf_parser.SE_SHOW_ID], i[lf_parser.SE_SHOW_ORIGINAL_TITLE]) for i in showsAll)

if os.path.isdir(DATA_DIRECTORY):
  shutil.rmtree(DATA_DIRECTORY)

os.mkdir(DATA_DIRECTORY)

for episode in episodesLast:
  showOriginalName = showsIDToOriginalName[episode[lf_parser.SE_SHOW_ID]]
  pathShow = os.path.join(DATA_DIRECTORY, MakeShowDirectoryName(showOriginalName))

  if not os.path.isdir(pathShow):
    os.mkdir(pathShow)
    artworkFileName = Tools.MakeArtworkFileName(showOriginalName, episode[lf_parser.SE_SHOW_SEASON_NUMBER])
    pathArtwork = os.path.join(ARTWORK_DIRECTORY, artworkFileName)
    # artwork
    if os.path.isfile(pathArtwork):
#      shutil.copyfile(pathArtwork, os.path.join(pathShow, "artwork.jpg"))
      MakeThumbnail(pathArtwork, os.path.join(pathShow, "artwork.jpg"))
    # info
    infoFileName = "info"
    config = UnicodeConfigParser()
    config.add_section(ST_INFO_SECTION_INFORMATION)
    config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_TITLE, episode[lf_parser.SE_SHOW_TITLE])
    config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ORIGINAL_TITLE, showOriginalName)
    config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_SEASON_NUMBER, episode[lf_parser.SE_SHOW_SEASON_NUMBER])
    config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ID, episode[lf_parser.SE_SHOW_ID])
    with codecs.open(os.path.join(pathShow, infoFileName), encoding = 'utf-8', mode = 'wb') as conffile: config.write(conffile)
