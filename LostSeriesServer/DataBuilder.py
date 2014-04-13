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
import Database


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



def UpdateFixedCancelStatus(idShow, isCanceled):
  db = Database.instance()
  showData = db.shows_full.find_one({Database.DATA_ID: makeShowDataID(idShow)})
  if not showData:
    logger().info("There is no such show with id: {0}".format(idShow))
    return
  #
  show = showData[Database.DATA_HISTORY][-1]
  #
  if SHOW_IS_CANCELED_FIXED in show and show[SHOW_IS_CANCELED_FIXED] == isCanceled:
    logger().info("Nothing to change. Fixed Cancel Status for show {0} is {1}".format(idShow, isCanceled))
    return
  #
  idSnapshotNew = Database.makeSnapshotID()
  logger().info("This snapshot will be: {0}".format(idSnapshotNew))
  # fix properties
  show[Database.SNAPSHOT_ID] = idSnapshotNew
  show[SHOW_IS_CANCELED_FIXED] = isCanceled
  #
  logger().info("Updating fixed show cancel status to: {0} {1}-'{2}'".format(isCanceled, show[SHOW_ID], show[SHOW_ORIGINAL_TITLE].encode('utf-8')))
  Database.insertDataToSnapshot(db.shows_full, show)
  #
  db.shows.drop()
  db.episodes.drop();
  Database.makeSnapshotCollection(db.episodes_full, "episodes", idSnapshotNew)
  Database.makeSnapshotCollection(db.shows_full, "shows", idSnapshotNew)
  Database.updateCurrentSnapshotID(idSnapshotNew)
  logger().info("Series updated. Total shows: {0}, episodes {1}".format(len(list(db.shows.find())), len(list(db.episodes.find()))))


def makeEpisodeDataID(showID, seasonNumber, episodeNumber):
  return '%ss%02de%02d' % (showID, seasonNumber, episodeNumber)


def makeShowDataID(showID):
  return showID


def isSeasonNumberAndEpisodeNumberLater(sNumLeft, eNumLeft, sNumRight, eNumRight):
  return (sNumLeft * 1000 + eNumLeft) > (sNumRight * 1000 + eNumRight)


def isEpisodeLater(episodeLeft, episodeRight):
  return isSeasonNumberAndEpisodeNumberLater(episodeLeft[SHOW_SEASON_NUMBER], episodeLeft[SHOW_SEASON_EPISODE_NUMBER], episodeRight[SHOW_SEASON_NUMBER], episodeRight[SHOW_SEASON_EPISODE_NUMBER])


def isEpisodeNew(episode, show):
  return isSeasonNumberAndEpisodeNumberLater(episode[SHOW_SEASON_NUMBER], episode[SHOW_SEASON_EPISODE_NUMBER], show[SHOW_LAST_SEASON_NUMBER], show[SHOW_LAST_EPISODE_NUMBER])


def UpdateData(records, checkCancel = True):
  logger().info("Updating series from LostFile.TV...")
  showsAll = LoadInfoAllShows()
  showsIDToShowInfo = dict((i[SE_SHOW_ID], (i[SE_SHOW_ORIGINAL_TITLE], i[SE_SHOW_TITLE])) for i in showsAll)
  #
  db = Database.instance()
  episodesNew = []
  #
  snapshotIDNew = Database.makeSnapshotID()
  logger().info("This snapshot will be: {0}".format(snapshotIDNew))
  #
  for record in records:
    idEpisodeData = makeEpisodeDataID(record[SE_SHOW_ID], record[SE_SHOW_SEASON_NUMBER], record[SE_EPISODE_NUMBER])
    episodeData = db.episodes_full.find_one({Database.DATA_ID: idEpisodeData})
    if not episodeData:
      episodeNew = \
      {
        Database.DATA_ID: idEpisodeData,
        Database.SNAPSHOT_ID: snapshotIDNew,
        SHOW_ID: record[SE_SHOW_ID],
        SHOW_SEASON_NUMBER: record[SE_SHOW_SEASON_NUMBER],
        SHOW_SEASON_EPISODE_NUMBER: record[SE_EPISODE_NUMBER],
        SHOW_SEASON_EPISODE_NAME: record[SE_EPISODE_NAME],
        SHOW_SEASON_SPISODE_ORIGINAL_NAME: record[SE_EPISODE_ORIGINAL_NAME],
        SHOW_SEASON_SPISODE_TRANSLATE_TIME: record[SE_EPISODE_TRANSLATE_DATE],
      }
      logger().info("Adding episode: {0}-'{1}'-{2}-{3}".format(record[SE_SHOW_ID], record[SE_EPISODE_ORIGINAL_NAME].encode('utf-8'), record[SE_SHOW_SEASON_NUMBER], record[SE_EPISODE_NUMBER]))
      Database.insertDataToSnapshot(db.episodes_full, episodeNew)
      episodesNew.append(episodeNew)
  #
  episodesByShow = dict()
  for episode in episodesNew:
    if not episode[SHOW_ID] in episodesByShow:
      episodesByShow[episode[SHOW_ID]] = list()
    episodesByShow[episode[SHOW_ID]].append(episode);
  #
  for idShow, groupOfEpisodes in episodesByShow.iteritems():
    episodeMax = groupOfEpisodes[0]
    for episode in groupOfEpisodes:
      if isEpisodeLater(episode, episodeMax):
        episodeMax = episode
    #
    try:
      showInfo = showsIDToShowInfo[idShow]
    except Exception, error:
      continue
    #
    idShowData = makeShowDataID(idShow)
    showData = db.shows_full.find_one({Database.DATA_ID: idShowData})
    showNew = \
    {
      Database.DATA_ID: idShowData,
      Database.SNAPSHOT_ID: snapshotIDNew,
      SHOW_ID: idShow,
      SHOW_TITLE: showInfo[1],
      SHOW_ORIGINAL_TITLE: showInfo[0],
      SHOW_LAST_SEASON_NUMBER: episodeMax[SHOW_SEASON_NUMBER],
      SHOW_LAST_EPISODE_NUMBER: episodeMax[SHOW_SEASON_EPISODE_NUMBER],
      SHOW_IS_CANCELED: False
    }
    #
    isEpisodeNewFlag = False
    if showData:
      show = showData[Database.DATA_HISTORY][-1]
      isEpisodeNewFlag = isEpisodeNew(episodeMax, show)
      # copy cancel status
      showNew[SHOW_IS_CANCELED] = show[SHOW_IS_CANCELED]
      if SHOW_IS_CANCELED_FIXED in show:
        showNew[SHOW_IS_CANCELED_FIXED] = show[SHOW_IS_CANCELED_FIXED]
    # recheck show cancel status
    isCancelStatusChangedFlag = False
    if checkCancel:
      isShowCanceled = IsShowCanceled(idShow)
      if showNew[SHOW_IS_CANCELED] != isShowCanceled:
        showNew[SHOW_IS_CANCELED] = isShowCanceled
        isCancelStatusChangedFlag = True
    #
    # reasons to update
    needToUpdate = (not showData) or isCancelStatusChangedFlag or isEpisodeNewFlag
    #
    if needToUpdate:
      logger().info("Reasons to update: New Show-{0}, Cancel Changed-{1}, isEpisodeNew-{2}".format(not showData, isCancelStatusChangedFlag, isEpisodeNewFlag))
      logger().info("Updating show: {0}-'{1}'".format(showNew[SHOW_ID], showNew[SHOW_ORIGINAL_TITLE].encode('utf-8')))
      Database.insertDataToSnapshot(db.shows_full, showNew)
  #
  db.shows.drop()
  db.episodes.drop();
  Database.makeSnapshotCollection(db.episodes_full, "episodes", snapshotIDNew)
  Database.makeSnapshotCollection(db.shows_full, "shows", snapshotIDNew)
  Database.updateCurrentSnapshotID(snapshotIDNew)
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
db = Database.instance()
# db.shows.drop()
# db.service.drop()
# db.episodes.drop()
# db.shows_full.drop()
# db.episodes_full.drop()

# UpdateFixedCancelStatus("150", True)
# UpdateFixedCancelStatus("152", True)

episodesPage1 = LoadInfoLastSeries(2)
UpdateData(episodesPage1)

for show in list(db.shows_full.find()):
  print len(show[Database.DATA_HISTORY]), show[Database.DATA_ID]
  if len(show[Database.DATA_HISTORY]) > 1:
    for rec in show[Database.DATA_HISTORY]:
      print rec

# for episode in list(db.episodes_full.find()):
#   print len(episode[Database.DATA_HISTORY]), episode[Database.DATA_ID]
#   for rec in episode[Database.DATA_HISTORY]:
#     print rec

UpdateArtworks(db)


