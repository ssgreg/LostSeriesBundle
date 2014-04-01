# -*- coding: utf-8 -*-
# 
# Database.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import pymongo


SNAPSHOT_ID = 'global_snapshot_id' # if change you should change javascript code below
DATA_ID = 'data_id' # if change you should change javascript code below
SNAPSHOT_NEXT_ID = 'global_snapshot_next_id'
DATA_HISTORY = 'history'


def instance():
  mongo = pymongo.MongoClient()
  #mongo.drop_database('lostseries')
  return mongo.lostseries


def makeUnsafeSnapshotID():
  return instance().service.find_and_modify(update={"$inc": { SNAPSHOT_NEXT_ID: 1 }}, new = True)


def updateUnsafeCurrentSnapshotID(snapshotID):
  return instance().service.find_and_modify(update={"$set": { SNAPSHOT_ID: snapshotID }}, new = True)


def makeSnapshotID():
  id = makeUnsafeSnapshotID()
  if not id:
    instance().service.insert({SNAPSHOT_NEXT_ID:0})
    id = makeUnsafeSnapshotID()
  return id[SNAPSHOT_NEXT_ID]


def updateCurrentSnapshotID(snapshotID):
  id = updateUnsafeCurrentSnapshotID(snapshotID)
  if not id:
    instance().service.insert({SNAPSHOT_ID: 0})
    id = updateUnsafeCurrentSnapshotID(snapshotID)
  return id


def updateCurrentSnapshotID(snapshotID):
  return instance().service.find_and_modify(update={"$set": { SNAPSHOT_ID: snapshotID }}, new = True)


def getSnapshotID():
  id = instance().service.find_one({SNAPSHOT_ID: {"$exists": True}})
  if not id:
    return 0
  return id[SNAPSHOT_ID]


def getSnapshotNextID():
  id = instance().service.find_one({SNAPSHOT_NEXT_ID: {"$exists": True}})
  if not id:
    return 0
  return id[SNAPSHOT_ID]


def insertDataToSnapshot(collection, data):
  collection.update({DATA_ID: data[DATA_ID]}, {'$push': {DATA_HISTORY: data}}, upsert = True);


def makeSnapshotCollection(collection, target, snapshotID = None, filter = ""):
  if not snapshotID:
    snapshotID = getSnapshotID()
  #
  reduce = '''function(key, values) { return values; }'''
  map = '''function()
    {
      var maxts = %d;
      var len = this.history.length;
      var res = 0;
      var ts = -1;
      for (var i = 0; i < len; i++)
      {
        if (this.history[i].global_snapshot_id > ts & this.history[i].global_snapshot_id <= maxts)
        {
          ts = this.history[i].global_snapshot_id;
          res = i;
        }
      }
      if (ts == -1)
      {
        return;
      }
      //
      value = this.history[res]
      filter = false;
      //
      %s
      //
      if (filter)
      {
        return;
      }
      //
      emit(this.data_id, value);
    }''' % (snapshotID, filter)
  # target could be {'inline':1} (for list instead of collection)
  return collection.map_reduce(map, reduce, target)
