# -*- coding: utf-8 -*-
# 
# lf_parser.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import bs4
import urllib2
import datetime
import logging
import logging.config


SE_EPISODE_NUMBER = "SeEpisodeNumber"
SE_EPISODE_NAME = "SeEpisodeName"
SE_EPISODE_ORIGINAL_NAME = "SeEpisodeOriginalName"
SE_EPISODE_TRANSLATE_DATE = "SeEpisodeTranslateDate"
SE_SHOW_ID = "SeShowID"
SE_SHOW_SEASON_NUMBER = "SeSeasonNumber"
SE_SHOW_TITLE = "SeTitle"
SE_SHOW_ORIGINAL_TITLE = "SeOriginalTitle"


class LFParserException(Exception):
  def __init__(self):
    pass


class LSParserSyntaxException(LFParserException):
  pass


# complete season reocord has '08 сезон' instead of episode and season numbers
def IsCompleteSeason(data):
  return data.find(u"сезон") != -1


def ParseDataEpisodeNumberWithSeasonNumber(data):
  posDot = data.find(".")
  #
  if posDot == -1:
    raise LSParserSyntaxException()
  #
  numberSeason = data[:posDot]
  numberEpisode = data[posDot + 1:]
  #
  if not numberEpisode.isdigit() or not numberEpisode.isdigit():
    raise LSParserSyntaxException()
  #
  return { SE_SHOW_SEASON_NUMBER: int(numberSeason), SE_EPISODE_NUMBER: int(numberEpisode) }


def ParseDataEpisodeName(data):
  posLeftBracket = data.find("(")
  posRightBracket = data.find(")")
  #
  if posLeftBracket == -1 or posRightBracket == -1:
    episodeName = data
    episodeOriginalName = data
  else:
    episodeName = data[:posLeftBracket - 1]
    episodeOriginalName = data[posLeftBracket + 1:posRightBracket]
  #
  return { SE_EPISODE_NAME: episodeName, SE_EPISODE_ORIGINAL_NAME: episodeOriginalName}


def ParseDataEpisodeTranslateDate(data):
  try:
    return datetime.datetime.strptime(data, '%d.%m.%Y %H:%M')
  except:
    raise LSParserSyntaxException()


def ParseDataShowID(data):
  posEquals = data.find("=")
  #
  if posEquals == -1:
    raise LSParserSyntaxException()
  #
  idShow = data[posEquals + 1:]
  if not idShow.isdigit():
    raise LSParserSyntaxException()
  #
  return int(idShow)


def HasNewSeries(tag):
  if tag.has_attr('style'):
    if "float:right;font-family:arial;font-size:18px;color:#000000" in tag['style']:
      return True
  return False


def HasTagAllSeries(tag):
  if tag.has_attr('class'):
    if "bb" in tag['class']:
      return True
  return False


def HasTagSeriesInAllSeries(tag):
  if tag.has_attr('class'):
    if "bb_a" in tag['class']:
      return True
  return False


def ParsePageLostFilmBrowse(page):
  seriesLast = []
  soup = bs4.BeautifulSoup(page)
  #
  for a in soup.find_all(HasNewSeries):
    # skip short 'whats new' (from right side of page)
    if a.parent.has_attr("id"):
      if "new_sd_list" in a.parent["id"]:
        break
    #
    try:
      # tags
      tagShowEpisode = a
      tagShowName = tagShowEpisode.findNextSibling("span")
      tagShowInfo = tagShowName.findNextSibling("br")
      # raw data
      showRawEpisodeNumber = tagShowEpisode.contents[2].strip()
      showRawName = tagShowName.contents[0].strip()
      showRawEpisodeName = tagShowInfo.find("span").next.contents[0].strip()
      showRawID = tagShowInfo.find("a")["href"].strip()
      showRawEpisodeTranslateDate = tagShowInfo.contents[6].contents[0].strip()
      # skip complete season records
      if IsCompleteSeason(showRawEpisodeNumber):
        continue
      #
      record = \
      {
        SE_SHOW_TITLE: showRawName,
        SE_SHOW_ID: ParseDataShowID(showRawID),
        SE_EPISODE_TRANSLATE_DATE: ParseDataEpisodeTranslateDate(showRawEpisodeTranslateDate)
      };
      record.update(ParseDataEpisodeName(showRawEpisodeName))
      record.update(ParseDataEpisodeNumberWithSeasonNumber(showRawEpisodeNumber))
      #
      seriesLast.append(record)
    except Exception, error:
      data = "ParsePageLostFilmBrowse: Undefined record: {0}".format(tagShowEpisode)
      if 'tagShowName' in vars():
        data += "{0}".format(tagShowName)
      if 'tagShowInfo' in vars():
        data += "{0}".format(tagShowInfo)
      logger = logging.getLogger(__name__)
      logger.info(data)
      logger.warning(data, exc_info=True)
      continue
  #
  if len(seriesLast) == 0:
    raise LSParserSyntaxException()
  #
  return seriesLast;


def ParsePageLostFilmSerials(page):
  seriesAll = []
  soup = bs4.BeautifulSoup(page)
  for a in soup.find(HasTagAllSeries).find_all(HasTagSeriesInAllSeries):
    try:
      showRawID = a["href"].strip()
      showRawName = a.contents[0].strip()
      showRawOriginalName = a.find("span").contents[0].strip()
      #
      record = \
      {
        SE_SHOW_ID: ParseDataShowID(showRawID),
        SE_SHOW_TITLE: showRawName,
        SE_SHOW_ORIGINAL_TITLE: ParseDataEpisodeName(showRawOriginalName)[SE_EPISODE_ORIGINAL_NAME]
      };
      #
      seriesAll.append(record)
    except Exception, error:
      continue
  #
  if len(seriesAll) == 0:
    raise LSParserSyntaxException()
  return seriesAll

def LoadPage(url):
  return urllib2.urlopen(url).read().decode('cp1251').encode('utf-8')


def LoadInfoLastSeries():
  # add "?o=15" to skip some episodes
  url = "http://www.lostfilm.tv/browse.php"
  page = LoadPage(url)
  return ParsePageLostFilmBrowse(page)


def LoadInfoAllShows():
  url = "http://www.lostfilm.tv/serials.php"
  page = LoadPage(url)
  return ParsePageLostFilmSerials(page)


logging.config.fileConfig('logging.ini')
print LoadInfoAllShows()