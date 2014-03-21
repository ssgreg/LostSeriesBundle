# -*- coding: utf-8 -*-
# 
# Tools.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import datetime


def ShowDirectoryNamePrefix():
  return "TVShow="


def ArtworkFileNamePrefix():
  return "artwork="


def RemoveDisallowedChars(str):
  disallowedFilenameChars = ':/\\'
  return ''.join(x for x in str if x not in disallowedFilenameChars)


def MakeShowDirectoryName(originalName):
  return ShowDirectoryNamePrefix() + '"' + RemoveDisallowedChars(originalName) + '"'


def MakeArtworkFileName(originalName, numberSeason):
  return '{0}"{1}"-{2}.jpg'.format(ArtworkFileNamePrefix(), RemoveDisallowedChars(originalName),  numberSeason)


def MakeSnapshotID():
  today = datetime.datetime.now()
  return today.strftime('%Y-%m%d-%H%M%S')
