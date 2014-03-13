import ConfigParser
import os
import codecs


class TVShowInfo:
  Title = ""
  OriginalTitle = ""
  Season = 0
  Artwork = ""


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


def GetTVShowFolderName(originalName):
  disallowedFilenameChars = ':/\\'
  normalizedName = ''.join(x for x in originalName if x not in disallowedFilenameChars)
  return GetTVShowFolderNamePrefix() + "\"" + normalizedName + "\""


def ListTVShowFolders(root):
  return [ f for f in os.listdir(root) if os.path.isdir(os.path.join(root, f)) and f.startswith(GetTVShowFolderNamePrefix()) ]


def ReadLostSeriesData(snapshot = ""):
  #
  dataFolderName = "LostSeriesData"
  latestFolderName = "Latest"
  infoFileName = "info"
  artworkFileName = "artwork.jpg"
  informationSectionName = "Information"
  titleValueName = "Title"
  originalTitleValueName = "OriginalTitle"
  seasonValueName = "Season"
  #
  dataPath = os.path.join(dataFolderName, latestFolderName if not snapshot else snapshot)
  data = []
  for folder in ListTVShowFolders(dataPath):
    #
    print "Anasyled folder %s" % folder
    config = ConfigParser.ConfigParser()
    config.readfp(codecs.open(os.path.join(dataPath, folder, infoFileName), "r", "utf8"))
    #
    info = TVShowInfo()
    info.Title = config.get(informationSectionName, titleValueName)
    info.OriginalTitle = config.get(informationSectionName, originalTitleValueName)
    info.Season = config.getint(informationSectionName, seasonValueName)
    info.Artwork = ReadFile(os.path.join(dataPath, folder, artworkFileName))
    data.append(info)
  #
  return data
