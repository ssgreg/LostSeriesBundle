import urllib2
from urllib2 import urlopen

def Worker():
  try:
    page = urllib2.urlopen("http://www.lostfilm.tv/serials.php").read().decode('cp1251').encode('utf-8')
  except Exception, error:
    print str(error)
    return "ERROR"

  print page
