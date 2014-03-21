# -*- coding: utf-8 -*-
# 
# DataBuilder.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import pymongo
from Storage import *
from bson.binary import Binary
from lf_parser import *
import Image
import dropbox
import StringIO
import Tools

#
# DropboxArtworkUpdater
#

class DropboxArtworkUpdater:
  def __init__(self):
    appKey = 'y1yob2s5uyfzivq'
    appSecret = '6nv3t3h6h0a5z5b'
    # flow = dropbox.client.DropboxOAuth2FlowNoRedirect(app_key, app_secret)
    # authorize_url = flow.start()
    # access_token, user_id = flow.finish('8Dcg4wsNg_UAAAAAAAAAAR0CUe5wGVbLltfoR7Wa1kY')
    # print access_token, user_id
    token = 'jClEfTkq2IYAAAAAAAAAAfpHbJbfchT8L0syxBQZPtJrnoWFOXa5_wGGba6Wnofl'
    self._path = '/LostSeries/Artworks/'
    self._client = dropbox.client.DropboxClient(token)
    self._metadata = self._client.metadata(self._path)
    self._rawExtension = '.raw'
    self._artworksToDelete = list()

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    for artwork in self._artworksToDelete:
      if self._rawExtension in artwork:
        print "Deleting", artwork
        self._client.file_move(artwork, artwork.replace(self._rawExtension, ''))

  def makeArtworkFileName(self, showOriginalName, showSeasonNumber):
    return Tools.MakeArtworkFileName(showOriginalName, showSeasonNumber) + self._rawExtension

  def hasArtwork(self, showOriginalName, showSeasonNumber):
    name = self.makeArtworkFileName(showOriginalName, showSeasonNumber)
    return any(name in i['path'] for i in self._metadata['contents'])

  def getArtwork(self, showOriginalName, showSeasonNumber):
    name = self._path + self.makeArtworkFileName(showOriginalName, showSeasonNumber)
    self._artworksToDelete.append(name)
    return self._client.get_file(name).read()


def MakeThumbnail(imageData):
  fileObjectInput = StringIO.StringIO()
  fileObjectInput.write(imageData)
  fileObjectInput.seek(0)
  im = Image.open(fileObjectInput)
  im = im.resize((188, 188), Image.ANTIALIAS)
  fileObjectOutput = StringIO.StringIO()
  im.save(fileObjectOutput, "JPEG", quality=90)
  return fileObjectOutput.getvalue()


def UpdateArtworks(sectionData, sectionArtworks):
  data = list(sectionData.find())

  with DropboxArtworkUpdater() as artworkUpdater:
    dataArtworks = list(sectionArtworks.find())
    for show in data:
      #
      hasArtwork = artworkUpdater.hasArtwork(show[SHOW_ORIGINAL_TITLE], show[SHOW_LAST_SEASON_NUMBER])
      if not hasArtwork:
        try:
          artworkShow = next(i for i in dataArtworks if i[SHOW_ID] == show[SHOW_ID])
        except Exception, error:
          print "No artwork for:", show[SHOW_ORIGINAL_TITLE], show[SHOW_LAST_SEASON_NUMBER]
        continue
      #
      artworkShow = None
      try:
        artworkShow = next(i for i in dataArtworks if i[SHOW_ID] == show[SHOW_ID])
      except Exception, error:
        pass
      if not artworkShow:
        artworkShow = \
        {
          SHOW_ID: show[SHOW_ID],
          SHOW_SEASONS: list()
        }
        dataArtworks.append(artworkShow)
      #
      artworkSeason = None
      imageData = artworkUpdater.getArtwork(show[SHOW_ORIGINAL_TITLE], show[SHOW_LAST_SEASON_NUMBER])
      try:
        artworkSeason = next(i for i in artworkShow[SHOW_SEASONS] if i[SHOW_SEASON_NUMBER] == show[SHOW_LAST_SEASON_NUMBER])
        artworkSeason[SHOW_SEASON_ARTWORK] = Binary(imageData)
        artworkSeason[SHOW_SEASON_ARTWORK_THUMBNAIL] = Binary(MakeThumbnail(imageData))
        artworkSeason[SHOW_SEASON_ARTWORK_SNAPSHOT] = Tools.MakeSnapshotID()
        print "Updating artwork for:", show[SHOW_ORIGINAL_TITLE], show[SHOW_LAST_SEASON_NUMBER]
      except Exception, error:
        pass
      if not artworkSeason:
        artworkSeason = \
        {
          SHOW_SEASON_NUMBER: show[SHOW_LAST_SEASON_NUMBER],
          SHOW_SEASON_ARTWORK: Binary(imageData),
          SHOW_SEASON_ARTWORK_THUMBNAIL: Binary(MakeThumbnail(imageData)),
          SHOW_SEASON_ARTWORK_SNAPSHOT: Tools.MakeSnapshotID(),
        }
        print "New artwork for:", show[SHOW_ORIGINAL_TITLE], show[SHOW_LAST_SEASON_NUMBER]
        artworkShow[SHOW_SEASONS].append(artworkSeason)
      #
    for record in dataArtworks:
      sectionArtworks.remove({SHOW_ID: record[SHOW_ID]})
      sectionArtworks.insert(record)


def UpdateData(sectionData):
  showsAll = LoadInfoAllShows()
  episodesLast = LoadInfoLastSeries(1)
  showsIDToOriginalName = dict((i[SE_SHOW_ID], i[SE_SHOW_ORIGINAL_TITLE]) for i in showsAll)

  data = list(sectionData.find())

  for record in episodesLast:
    #
    # show
    show = None
    try:
      show = next(i for i in data if i[SHOW_ID] == record[SE_SHOW_ID])
    except Exception, error:
      pass
    if not show:
      show = \
      {
        SHOW_ID: record[SE_SHOW_ID],
        SHOW_TITLE: record[SE_SHOW_TITLE],
        SHOW_LAST_SEASON_NUMBER: 0,
        SHOW_LAST_EPISODE_NUMBER: 0,
        SHOW_ORIGINAL_TITLE: showsIDToOriginalName[record[SE_SHOW_ID]],
        SHOW_SEASONS: list(),
      }
      print "New show:", show[SHOW_ORIGINAL_TITLE].encode('utf-8')
      data.append(show)
    #
    show[SHOW_LAST_SEASON_NUMBER] = max(show[SHOW_LAST_SEASON_NUMBER], record[SE_SHOW_SEASON_NUMBER])
    show[SHOW_LAST_EPISODE_NUMBER] = max(show[SHOW_LAST_EPISODE_NUMBER], record[SE_EPISODE_NUMBER])
    #
    # season
    season = None
    try:
      season = next(i for i in show[SHOW_SEASONS] if i[SHOW_SEASON_NUMBER] == record[SE_SHOW_SEASON_NUMBER])
    except Exception, error:
      pass
    if not season:
      season = \
      {
        SHOW_SEASON_NUMBER: record[SE_SHOW_SEASON_NUMBER],
        SHOW_SEASON_EPISODES: list(),
      }
      print "New season:", record[SE_SHOW_SEASON_NUMBER]
      show[SHOW_SEASONS].append(season)
    #
    # episode
    episode = None
    try:
      episode = next(i for i in season[SHOW_SEASON_EPISODES] if i[SHOW_SEASON_EPISODE_NUMBER] == record[SE_EPISODE_NUMBER])
    except Exception, error:
      pass
    if not episode:
      episode = \
      {
        SHOW_SEASON_EPISODE_NUMBER: record[SE_EPISODE_NUMBER],
        SHOW_SEASON_EPISODE_NAME: record[SE_EPISODE_NAME],
        SHOW_SEASON_SPISODE_ORIGINAL_NAME: record[SE_EPISODE_ORIGINAL_NAME],
        SHOW_SEASON_SPISODE_TRANSLATE_TIME: record[SE_EPISODE_TRANSLATE_DATE],
      }
      print "New episode:", record[SE_EPISODE_NUMBER], record[SE_EPISODE_ORIGINAL_NAME].encode('utf-8')
      season[SHOW_SEASON_EPISODES].append(episode)

  for record in data:
    sectionData.remove({SHOW_ID: record[SHOW_ID]})
    sectionData.insert(record)


mongo = pymongo.MongoClient()
#mongo.drop_database('lostseries')
db = mongo['lostseries']

sectionService = db[SECTION_SERVICE]
sectionData = db[SECTION_DATA]
sectionArtworks = db[SECTION_ARTWORKS]

print "data"
UpdateData(sectionData)
print "artworks"
UpdateArtworks(sectionData, sectionArtworks)


#  i.SHOW_ID == 1 for i in data
  # print showOriginalName

# sectionData.insert(post)
# for i in list(db.collection_names()):
#   print i




# import os
# import shutil
# import logging.config
# import ConfigParser
# import codecs
# import Image


# import lf_parser
# import Tools
# from Storage import *



# DATA_DIRECTORY = "LoadSeriesData1"
# SHOW_DIRECTORY_FORMAT = 'TVShow="{0}"'
# ARTWORK_DIRECTORY = "LostSeriesArtworks"


# class UnicodeConfigParser(ConfigParser.RawConfigParser):

#     def __init__(self, defaults=None, dict_type=dict):
#         ConfigParser.RawConfigParser.__init__(self, defaults, dict_type)
       
#     def write(self, fp):
#         """Fixed for Unicode output"""
#         if self._defaults:
#             fp.write("[%s]\n" % DEFAULTSECT)
#             for (key, value) in self._defaults.items():
#                 fp.write("%s = %s\n" % (key, unicode(value).replace('\n', '\n\t')))
#             fp.write("\n")
#         for section in self._sections:
#             fp.write("[%s]\n" % section)
#             for (key, value) in self._sections[section].items():
#                 if key != "__name__":
#                     fp.write("%s = %s\n" %
#                              (key, unicode(value).replace('\n','\n\t')))
#             fp.write("\n")

#     # This function is needed to override default lower-case conversion
#     # of the parameter's names. They will be saved 'as is'.
#     def optionxform(self, strOut):
#         return strOut


# def MakeShowDirectoryName(showOriginalName):
#   return SHOW_DIRECTORY_FORMAT.format(showOriginalName)


# def MakeThumbnail(src, dst):
#   size = 188, 188
#   im = Image.open(src)
#   im = im.resize((188, 188), Image.ANTIALIAS)
#   im.save(dst, "JPEG", quality=90)



# logging.config.fileConfig('logging.ini')

# showsAll = lf_parser.LoadInfoAllShows()
# episodesLast = lf_parser.LoadInfoLastSeries(3)

# showsIDToOriginalName = dict((i[lf_parser.SE_SHOW_ID], i[lf_parser.SE_SHOW_ORIGINAL_TITLE]) for i in showsAll)

# if os.path.isdir(DATA_DIRECTORY):
#   shutil.rmtree(DATA_DIRECTORY)

# os.mkdir(DATA_DIRECTORY)

# for episode in episodesLast:
#   showOriginalName = showsIDToOriginalName[episode[lf_parser.SE_SHOW_ID]]
#   pathShow = os.path.join(DATA_DIRECTORY, MakeShowDirectoryName(showOriginalName))

#   if not os.path.isdir(pathShow):
#     os.mkdir(pathShow)
#     artworkFileName = Tools.MakeArtworkFileName(showOriginalName, episode[lf_parser.SE_SHOW_SEASON_NUMBER])
#     pathArtwork = os.path.join(ARTWORK_DIRECTORY, artworkFileName)
#     # artwork
#     if os.path.isfile(pathArtwork):
# #      shutil.copyfile(pathArtwork, os.path.join(pathShow, "artwork.jpg"))
#       MakeThumbnail(pathArtwork, os.path.join(pathShow, "artwork.jpg"))
#     #
# #    print lf_parser.IsShowClosed(episode[lf_parser.SE_SHOW_ID]), episode[lf_parser.SE_SHOW_TITLE].encode('utf-8')

#   infoFileName = "info"
#   pathInfo = os.path.join(pathShow, infoFileName)
#   config = UnicodeConfigParser()
#   #
#   if os.path.isfile(pathInfo):
#     config.readfp(codecs.open(pathInfo, "r", "utf8"))
#   else:
#     # information section
#     config.add_section(ST_INFO_SECTION_INFORMATION)
#     config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_TITLE, episode[lf_parser.SE_SHOW_TITLE])
#     config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ORIGINAL_TITLE, showOriginalName)
#     config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_SEASON_NUMBER, episode[lf_parser.SE_SHOW_SEASON_NUMBER])
#     config.set(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ID, episode[lf_parser.SE_SHOW_ID])

#   # episodes section
#   sectionEpisode = ST_INFO_SECTION_EPISODE.format(episode[lf_parser.SE_SHOW_SEASON_NUMBER], episode[lf_parser.SE_EPISODE_NUMBER])
#   config.add_section(sectionEpisode)
#   config.set(sectionEpisode, ST_INFO_VALUE_NAME, episode[lf_parser.SE_EPISODE_NAME])
#   config.set(sectionEpisode, ST_INFO_VALUE_ORIGINAL_NAME, episode[lf_parser.SE_EPISODE_ORIGINAL_NAME])
#   #
#   with codecs.open(pathInfo, encoding = 'utf-8', mode = 'wb') as conffile: config.write(conffile)
