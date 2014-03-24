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
import logging
import logging.config


def logger():
  return logging.getLogger(__name__)

#
# DropboxArtworkUpdater
#

STORAGE_ARTWORK_PATH = 'path'
STORAGE_ARTWORK_ID = 'id'
STORAGE_ARTWORK_SEASON = 'season'
STORAGE_ARTWORK_ISNEW = 'is_new'


class StorageArtworksDropbox:
  def __init__(self):
    # appKey = 'y1yob2s5uyfzivq'
    # appSecret = '6nv3t3h6h0a5z5b'
    # flow = dropbox.client.DropboxOAuth2FlowNoRedirect(app_key, app_secret)
    # authorize_url = flow.start()
    # access_token, user_id = flow.finish('8Dcg4wsNg_UAAAAAAAAAAR0CUe5wGVbLltfoR7Wa1kY')
    # print access_token, user_id
    token = 'jClEfTkq2IYAAAAAAAAAAfpHbJbfchT8L0syxBQZPtJrnoWFOXa5_wGGba6Wnofl'
    self._path = '/LostSeries/Artworks/'
    self._newExtension = 'raw'
    self._artworksToDelete = list()
    logger().debug("Connecting to dropbox...")
    self._client = dropbox.client.DropboxClient(token)

  def artworks(self):
    logger().info("Getting artworks folder metadata...")
    metadata = self._client.metadata(self._path)
    result = []
    for i in metadata['contents']:
      record = self._parseArtwork(i['path'])
      if record != None:
        result.append(record)
    #
    return result

  def markArtworkAsNotNew(self, artwork):
    name = artwork[STORAGE_ARTWORK_PATH];
    logger().info("Marking artwork as not new {0}...".format(name))
    return self._client.file_move(name, name.replace('.' + self._newExtension, ''))

  def artwork(self, artwork):
    logger().debug("Getting artwork data for {0}...".format(artwork[STORAGE_ARTWORK_PATH]))
    return self._client.get_file(artwork[STORAGE_ARTWORK_PATH]).read()

  def _parseArtwork(self, artwork):
    partsWithoutExtension = artwork.split('.')
    parts = partsWithoutExtension[0].split('-')
    #
    if len(parts) < 3 or not parts[2].isdigit():
      logger().warning("Skipped: {0}".format(artwork))
      return None
    #
    result = \
    {
      STORAGE_ARTWORK_PATH: artwork,
      STORAGE_ARTWORK_ID: parts[1],
      STORAGE_ARTWORK_SEASON: int(parts[2]),
      STORAGE_ARTWORK_ISNEW: partsWithoutExtension[-1] == self._newExtension
    }
    return result


def MakeThumbnail(imageData):
  fileObjectInput = StringIO.StringIO()
  fileObjectInput.write(imageData)
  fileObjectInput.seek(0)
  im = Image.open(fileObjectInput)
  im = im.resize((188, 188), Image.ANTIALIAS)
  fileObjectOutput = StringIO.StringIO()
  im.save(fileObjectOutput, "JPEG", quality=90)
  return fileObjectOutput.getvalue()


def UpdateArtworks(db):
  logger().info("Updating artworks from the storage...")
  collArtworks = db.artworks
  storageArtworks = StorageArtworksDropbox()
  #
  for artwork in storageArtworks.artworks():
    artworkBase = collArtworks.find_one({ SHOW_ID: artwork[STORAGE_ARTWORK_ID], SHOW_SEASON_NUMBER: artwork[STORAGE_ARTWORK_SEASON] })
    #
    if artworkBase:
      if artwork[STORAGE_ARTWORK_ISNEW]:
        logger().info("Updating artwork with: {0}".format(artwork[STORAGE_ARTWORK_PATH]))
        imageData = storageArtworks.artwork(artwork)
        record = \
        {
          "$set":
          {
            SHOW_SEASON_ARTWORK: Binary(imageData),
            SHOW_SEASON_ARTWORK_THUMBNAIL: Binary(MakeThumbnail(imageData)),
            SHOW_SEASON_ARTWORK_SNAPSHOT: Tools.MakeSnapshotID(),
          }
        }
        collArtworks.update(artworkBase, record, False, False)
      else:
        pass
    else:
      imageData = storageArtworks.artwork(artwork)
      record = \
      {
        SHOW_ID: artwork[STORAGE_ARTWORK_ID],
        SHOW_SEASON_NUMBER: artwork[STORAGE_ARTWORK_SEASON],
        SHOW_SEASON_ARTWORK: Binary(imageData),
        SHOW_SEASON_ARTWORK_THUMBNAIL: Binary(MakeThumbnail(imageData)),
        SHOW_SEASON_ARTWORK_SNAPSHOT: Tools.MakeSnapshotID(),
      }
      logger().info("Adding artwork with: {0}".format(artwork[STORAGE_ARTWORK_PATH]))
      collArtworks.insert(record)
    #
    if artwork[STORAGE_ARTWORK_ISNEW]:
      storageArtworks.markArtworkAsNotNew(artwork)
  #
  logger().info("Artworks updated")


def UpdateCancelStatus(show):
  isCanceled = IsShowCanceled(show[SHOW_ID])
  if SHOW_IS_CANCELED in show and show[SHOW_IS_CANCELED] == isCanceled:
    return
  showUpdate = \
  {
    "$set":
    {
      SHOW_IS_CANCELED: isCanceled
    }
  }
  logger().info("Updating show cancel status to: {0} {1}-'{2}'".format(isCanceled, show[SHOW_ID], show[SHOW_ORIGINAL_TITLE].encode('utf-8')))
  db.shows.update(show, showUpdate, False, False)


def UpdateLastSeasonNumberAndEpisodeNumber(show, newSeasonNumber, newEpisodeNumber):
  newSeasonNumberIsBigger = newSeasonNumber > show[SHOW_LAST_SEASON_NUMBER]
  newEpisodeNumberIsBiggerWithEqualSeasonNumbers = (newSeasonNumber == show[SHOW_LAST_SEASON_NUMBER] and newEpisodeNumber > show[SHOW_LAST_EPISODE_NUMBER])
  if newSeasonNumberIsBigger or newEpisodeNumberIsBiggerWithEqualSeasonNumbers:
    showUpdate = \
    {
      "$set":
      {
        SHOW_LAST_SEASON_NUMBER: newSeasonNumber,
        SHOW_LAST_EPISODE_NUMBER: newEpisodeNumber,
      }
    }
    logger().info("Updating show: {0}-'{1}'".format(show[SHOW_ID], show[SHOW_ORIGINAL_TITLE].encode('utf-8')))
    db.shows.update(show, showUpdate, False, False)


def UpdateData(db, episodes):
  logger().info("Updating series from LostFile.TV...")
  showsAll = LoadInfoAllShows()
  showsIDToOriginalName = dict((i[SE_SHOW_ID], i[SE_SHOW_ORIGINAL_TITLE]) for i in showsAll)
  #
  result = []
  #
  for record in episodes:
    # show
    show = db.shows.find_one({ SHOW_ID: record[SE_SHOW_ID] })
    if not show:
      #
      try:
        originalTitle = showsIDToOriginalName[record[SE_SHOW_ID]]
      except Exception, error:
        continue
      #
      show = \
      {
        SHOW_ID: record[SE_SHOW_ID],
        SHOW_TITLE: record[SE_SHOW_TITLE],
        SHOW_ORIGINAL_TITLE: originalTitle,
        SHOW_LAST_SEASON_NUMBER: record[SE_SHOW_SEASON_NUMBER],
        SHOW_LAST_EPISODE_NUMBER: record[SE_EPISODE_NUMBER],
      }
      logger().info("Adding show: {0}-'{1}'".format(show[SHOW_ID], show[SHOW_ORIGINAL_TITLE].encode('utf-8')))
      db.shows.insert(show)
    else:
      UpdateLastSeasonNumberAndEpisodeNumber(show, record[SE_SHOW_SEASON_NUMBER], record[SE_EPISODE_NUMBER])
    # episode
    episode = db.episodes.find_one({ SHOW_ID: record[SE_SHOW_ID], SHOW_SEASON_NUMBER: record[SE_SHOW_SEASON_NUMBER], SHOW_SEASON_EPISODE_NUMBER: record[SE_EPISODE_NUMBER]})
    if not episode:
      episode = \
      {
        SHOW_ID: record[SE_SHOW_ID],
        SHOW_SEASON_NUMBER: record[SE_SHOW_SEASON_NUMBER],
        SHOW_SEASON_EPISODE_NUMBER: record[SE_EPISODE_NUMBER],
        SHOW_SEASON_EPISODE_NAME: record[SE_EPISODE_NAME],
        SHOW_SEASON_SPISODE_ORIGINAL_NAME: record[SE_EPISODE_ORIGINAL_NAME],
        SHOW_SEASON_SPISODE_TRANSLATE_TIME: record[SE_EPISODE_TRANSLATE_DATE],
      }
      logger().info("Adding episode: {0}-'{1}'-'{2}'-{3}-{4}".format(show[SHOW_ID], show[SHOW_ORIGINAL_TITLE].encode('utf-8'), episode[SHOW_SEASON_SPISODE_ORIGINAL_NAME].encode('utf-8'), episode[SHOW_SEASON_NUMBER], episode[SHOW_SEASON_EPISODE_NUMBER]))
      db.episodes.insert(episode)
      result.append(episode)
      # recheck cancel status for new episode
      UpdateCancelStatus(show)
  #
  logger().info("Series updated. Total shows: {0}, episodes {1}".format(len(list(db.shows.find())), len(list(db.episodes.find()))))


def UpdateShowsCancelStatus(db):
  logger().info("Updating series cancel status...")
  for show in db.shows.find():
    if SHOW_IS_CANCELED in show and show[SHOW_IS_CANCELED]:
      continue
    #
    UpdateCancelStatus(show)
  #
  logger().info("Cancel statuses were updated")



logging.config.fileConfig('logging.ini')
mongo = pymongo.MongoClient()
#mongo.drop_database('lostseries')
db = mongo.lostseries
#db.shows.drop()
#db.episodes.drop()

episodesPage1 = LoadInfoLastSeries(1)
episodesNew = UpdateData(db, episodesPage1)
UpdateArtworks(db)
#UpdateShowsCancelStatus(db)

print len(list(db.shows.find({ SHOW_IS_CANCELED: False })))
# for record in list(db.shows.find({ SHOW_IS_CANCELED: False })):
#   print record[SHOW_ORIGINAL_TITLE].encode('utf-8'), record[SHOW_ID]