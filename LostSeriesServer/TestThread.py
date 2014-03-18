import pymongo

def printAllRecords(section):
  records = section.find().sort([("token", pymongo.DESCENDING)])
  for i, d in enumerate(records):
    print i, d

def removeAllRecords(section):
  records = section.find().sort([("token", pymongo.DESCENDING)])
  for i, d in enumerate(records):
    section.remove(d)


#  for idc in subscriptionsSection.find({"token": message.token}):
#    subscriptions = subscriptions + idc["tags"]
  #


client = pymongo.MongoClient()
db = client['lostseries-database']
subscriptionsSection = db.subscriptions

printAllRecords(subscriptionsSection)
