import pymongo
from Storage import *

from bson.binary import Binary

def printAllRecords(section):
  records = section.find().sort([("token", pymongo.DESCENDING)])
  for i, d in enumerate(records):
    print i, d

def removeAllRecords(section):
  records = section.find().sort([("token", pymongo.DESCENDING)])
  for i, d in enumerate(records):
    section.remove(d)


  #


data = ReadFile('LoadSeriesData1/TVShow="Bitten"/artwork.jpg')
client = pymongo.MongoClient()
#db = client['lostseries-database']
#subscriptionsSection = db.subscriptions
#printAllRecords(subscriptionsSection)

#client.drop_database('test')

db = client['test']


post = \
{
  "data": Binary(data),
  "snapshot": "10"
}
subscriptionsSection = db.test
subscriptionsSection.insert(post)
a = list(subscriptionsSection.find())
for i in a:
  print i

records = subscriptionsSection.find().sort([("snapshot", pymongo.DESCENDING)])
# for i, d in enumerate(records):
#   print 1
