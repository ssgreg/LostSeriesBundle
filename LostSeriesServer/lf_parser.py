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


SE_EPISODE_NUMBER = "SeEpisodeNumber"
SE_SEASON_NUMBER = "SeSeasonNumber"
SE_TITLE = "SeTitle"
SE_EPISODE_NAME = "SeEpisodeName"
SE_EPISODE_ORIGINAL_NAME = "SeEpisodeOriginalName"
SE_EPISODE_TRANSLATE_DATE = "SeEpisodeTranslateDate"


class LFParserException(Exception):
  def __init__(self):
    pass


class LSParserSyntaxException(LFParserException):
  pass


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
  return { SE_SEASON_NUMBER: int(numberSeason), SE_EPISODE_NUMBER: int(numberEpisode) }


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

def HasNewSeries(tag):
  if tag.has_attr('style'):
    if "float:right;font-family:arial;font-size:18px;color:#000000" in tag['style']:
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
      showRawEpisodeTranslateDate = tagShowInfo.contents[6].contents[0].strip()
    except Exception, error:
      raise LSParserSyntaxException()
    #
    record = \
    {
      SE_TITLE: showRawName,
      SE_EPISODE_TRANSLATE_DATE: ParseDataEpisodeTranslateDate(showRawEpisodeTranslateDate)
    };
    record.update(ParseDataEpisodeName(showRawEpisodeName))
    record.update(ParseDataEpisodeNumberWithSeasonNumber(showRawEpisodeNumber))
    print record

    seriesLast.append(record)
  #
  return seriesLast;


def LoadPage(url):
  return urllib2.urlopen(url).read().decode('cp1251').encode('utf-8')


def LoadInfoLastSeries():
  url = "http://www.lostfilm.tv/browse.php"
  page = LoadPage(url)
  return ParsePageLostFilmBrowse(page)


print LoadInfoLastSeries()