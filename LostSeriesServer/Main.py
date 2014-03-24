import zmq
import sys, traceback
import unicodedata
import time
import threading
import random
import pymongo
import datetime
#
from Cache import DataCache
import LostSeriesProtocol_pb2
import Snapshot
from Storage import *


def HandleSeriesRequest(message):
  print "Handling SeriesRequest..."
  sectionData, sectionArtwors = DataCache.Instance().GetData()
  #
  response = LostSeriesProtocol_pb2.SeriesResponse()
  for record in list(sectionData.find({ SHOW_IS_CANCELED: False })):
    showInfo = response.shows.add()
    showInfo.title = record[SHOW_TITLE]
    showInfo.originalTitle = record[SHOW_ORIGINAL_TITLE]
    showInfo.seasonNumber = record[SHOW_LAST_SEASON_NUMBER]
    showInfo.id = str(record[SHOW_ID])
    showInfo.snapshot = Snapshot.GetLatestSnapshot()
  return {"message": response, "data": None}


def HandleArtworkRequest(message):
  print "Handling ArtworkRequest..."
  sectionData, sectionArtwors = DataCache.Instance().GetData()
  #
  response = LostSeriesProtocol_pb2.ArtworkResponse()
  #
  artwork = ""
  try:
    show = sectionData.find_one({ SHOW_ID: message.id })
    artwork = sectionArtwors.find_one({ SHOW_ID: show[SHOW_ID] })[SHOW_SEASON_ARTWORK_THUMBNAIL]
  except Exception as e:
    print traceback.format_exc()
  #
  return {"message": response, "data": artwork}


def HandleSetSubscriptionRequest(message):
  print "Handling SetSubscriptionRequest..."
  response = LostSeriesProtocol_pb2.SetSubscriptionResponse()
  #
  subscriptions = []
  for record in message.subscriptions:
    subscriptions.append(record.id)
  #
  subscriptions = list(set(subscriptions))
  print "New records in database:"
  print subscriptions
  print "end"
  post = \
  {
    "token": message.token,
    "date": datetime.datetime.utcnow(),
    "tags": subscriptions,
  }
  #
  client = pymongo.MongoClient()
  db = client['lostseries-database']
  subscriptionsSection = db.subscriptions
  subscriptionsSection.remove({"token": message.token})
  subscriptionsSection.insert(post)
  #
  response.result = True
  return { "message": response, "data": None }


def HandleGetSubscriptionRequest(message):
  print "Handling HandleGetSubscriptionRequest..."
  #
  response = LostSeriesProtocol_pb2.GetSubscriptionResponse()
  response.token = message.token
  #
  client = pymongo.MongoClient()
  db = client['lostseries-database']
  subscriptionsSection = db.subscriptions
  #
  subscriptions = []
  for idc in subscriptionsSection.find({"token": message.token}):
    subscriptions = subscriptions + idc["tags"]
  #
  for subscription in subscriptions:
    record = response.subscriptions.add()
    record.id = subscription
  #
  return {"message": response, "data": None}


def ParseData(data):
  message = LostSeriesProtocol_pb2.Message()
  message.ParseFromString(data)
  return message


def SerializeMessage(message):
  response = LostSeriesProtocol_pb2.Message()
  #
  if type(message) is LostSeriesProtocol_pb2.SeriesResponse:
    print "Serializing SeriesResponse"
    response.seriesResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.ArtworkResponse:
    print "Serializing ArtworkResponse"
    response.artworkResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.SetSubscriptionResponse:
    print "Serializing SetSubscriptionResponse"
    response.setSubscriptionResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.GetSubscriptionResponse:
    print "Serializing GetSubscriptionResponse"
    response.getSubscriptionResponse.CopyFrom(message)
  #
  data = response.SerializeToString()
  return data


def DispatchMessage(message):
  print "Dispatching a message %s" % (message)
  #
  if message.HasField("seriesRequest"):
    response = HandleSeriesRequest(message.seriesRequest)
  elif message.HasField("artworkRequest"):
    response = HandleArtworkRequest(message.artworkRequest)
  elif message.HasField("setSubscriptionRequest"):
    response = HandleSetSubscriptionRequest(message.setSubscriptionRequest)
  elif message.HasField("getSubscriptionRequest"):
    response = HandleGetSubscriptionRequest(message.getSubscriptionRequest)
  else:
    raise Exception("Unknown message!");
  #
  return response


def MessageLoop(socket):
  while True:
    try:
      request = socket.recv()
      print "Handle!"
      #
      requestMessage = ParseData(request)
      response = DispatchMessage(requestMessage)
      #
      binaryResponse = SerializeMessage(response["message"])
      if response["data"] is None:
        socket.send(binaryResponse)
      else:
        socket.send(binaryResponse, zmq.SNDMORE)
        socket.send(response["data"])
      #
    except Exception as e:
      print "Handling run-time exception:", e
      print traceback.format_exc()
      # to remove
      return


def Main():
  print "LostSeries Server started"
  #
  context = zmq.Context()
  socket = context.socket(zmq.REP)
  socket.bind("tcp://*:8500")
  MessageLoop(socket)


Main()
