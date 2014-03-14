import urllib2
import bs4

# http://www.lostfilm.tv/browse.php
# http://www.lostfilm.tv/serials.php

ONE = "1"

def has_class_but_no_id(tag):
  if tag.has_attr('style'):
    if "float:right;font-family:arial;font-size:18px;color:#000000" in tag['style']:
      return True
  return False

try:
  page = urllib2.urlopen("http://www.lostfilm.tv/browse.php").read().decode('cp1251').encode('utf-8')
  soup = bs4.BeautifulSoup(page)

  result = []

  for a in soup.find_all(has_class_but_no_id):

    if a.parent.has_attr("id"):
      if "new_sd_list" in a.parent["id"]:
        break

    tagShowEpisode = a
    tagShowName = tagShowEpisode.findNextSibling("span")
    tagShowInfo = tagShowName.findNextSibling("br")

    showEpisodeNumber = tagShowEpisode.contents[2].strip()
    showName = tagShowName.contents[0].encode('utf-8').strip()
    showEpisodeName = tagShowInfo.find("span").next.contents[0].encode('utf-8').strip()
    showEpisodeReleaseTime = tagShowInfo.contents[6].contents[0].encode('utf-8').strip()

    print "{0} {1} {2} {3}".format(showEpisodeNumber, showName, showEpisodeName, showEpisodeReleaseTime)

    record = { ONE:showEpisodeNumber, "2":showEpisodeReleaseTime};


    result.append(record)

  print result

except Exception, error:
  print str(error)

