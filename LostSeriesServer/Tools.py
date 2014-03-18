# -*- coding: utf-8 -*-
# 
# Tools.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#


def ShowDirectoryNamePrefix():
  return "TVShow="


def ArtworkFileNamePrefix():
  return "artwork="


def RemoveDisallowerChars(str):
  disallowedFilenameChars = ':/\\'
  return ''.join(x for x in str if x not in disallowedFilenameChars)


def MakeShowDirectoryName(originalName):
  return ShowDirectoryNamePrefix() + '"' + RemoveDisallowerChars(originalName) + '"'


def MakeArtworkFileName(originalName, numberSeason):
  return '{0}"{1}"-{2}.jpg'.format(ArtworkFileNamePrefix(), RemoveDisallowerChars(originalName),  numberSeason)
