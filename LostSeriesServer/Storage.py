import ConfigParser
import os
import codecs
import Tools
import pymongo


ST_INFO_SECTION_INFORMATION = "information"
ST_INFO_VALUE_TITLE = "title"
ST_INFO_VALUE_ORIGINAL_TITLE = "original_title"
ST_INFO_VALUE_SEASON_NUMBER = "season"
ST_INFO_VALUE_ID = "id"

ST_INFO_SECTION_EPISODE = "episode-{0}.{1}"
ST_INFO_VALUE_NAME = "name"
ST_INFO_VALUE_ORIGINAL_NAME = "original_name"


SHOW_ID = "ID"
SHOW_TITLE = "Title"
SHOW_ORIGINAL_TITLE = "OriginalTitle"
SHOW_LAST_SEASON_NUMBER = "LastSeasonNumber"
SHOW_LAST_EPISODE_NUMBER = "LastEpisodeNumber"
SHOW_IS_CANCELED = "IsCanceled"
SHOW_IS_CANCELED_FIXED = "IsCanceledFixed"
SHOW_SEASON_NUMBER = "SeasonNumber"
SHOW_SEASON_EPISODE_NUMBER = "EpisodeNumber"
SHOW_SEASON_EPISODE_NAME = "EpisodeName"
SHOW_SEASON_SPISODE_ORIGINAL_NAME = "EpisodeOriginalName"
SHOW_SEASON_SPISODE_TRANSLATE_TIME = "EpisodeTranslateTime"
SHOW_SEASON_ARTWORK = "SeasonArtwork"
SHOW_SEASON_ARTWORK_THUMBNAIL = "SeasonArtworkThumbnail"
SHOW_SEASON_ARTWORK_SNAPSHOT = "SeasonArtworkSnapshot"

SECTION_SERVICE = "LostSeriesService"
SECTION_ARTWORKS = "LostSeriesArtworks"
SECTION_DATA = "LostSeriesData"


class TVShowInfo:
  Title = ""
  OriginalTitle = ""
  Season = 0
  Artwork = ""
  ID = ""


def ReadFile(name):
  chunkSize = 8128
  array = ""
  with open(name, "rb") as f:
    while True:
      chunk = f.read(chunkSize)
      if chunk:
        array += chunk
      else:
        break
  #
  print len(array)
  return array


def GetTVShowFolderNamePrefix():
  return "TVShow="


def ListTVShowFolders(root):
  return [ f for f in os.listdir(root) if os.path.isdir(os.path.join(root, f)) and f.startswith(GetTVShowFolderNamePrefix()) ]


def ReadLostSeriesData(snapshot = ""):
  #
  # dataFolderName = "LoadSeriesData1"
  # latestFolderName = "Latest"
  # infoFileName = "info"
  # artworkFileName = "artwork.jpg"
  # #
  # dataPath = dataFolderName # os.path.join(dataFolderName, latestFolderName if not snapshot else snapshot)
  # data = []
  # for folder in ListTVShowFolders(dataPath):
  #   #
  #   print "Anasyled folder %s" % folder
  #   config = ConfigParser.ConfigParser()
  #   config.readfp(codecs.open(os.path.join(dataPath, folder, infoFileName), "r", "utf8"))
  #   #
  #   info = TVShowInfo()
  #   info.Title = config.get(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_TITLE)
  #   info.OriginalTitle = config.get(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ORIGINAL_TITLE)
  #   info.Season = config.getint(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_SEASON_NUMBER)
  #   info.ID = config.get(ST_INFO_SECTION_INFORMATION, ST_INFO_VALUE_ID)
  #   try:
  #     info.Artwork = ReadFile(os.path.join(dataPath, folder, artworkFileName))
  #   except Exception, error:
  #     pass
  #   data.append(info)
  # #
  mongo = pymongo.MongoClient()
  #mongo.drop_database('lostseries')
  db = mongo['lostseries']

  sectionService = db[SECTION_SERVICE]
  sectionData = db.shows
  sectionArtworks = db.artworks
  return (sectionData, sectionArtworks)
