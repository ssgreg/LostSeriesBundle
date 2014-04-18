import zmq
import sys, traceback
import unicodedata
import time
import threading
import random
import pymongo
import datetime
import logging
import logging.config
#
from Cache import DataCache
import LostSeriesProtocol_pb2
import Snapshot
from Storage import *
import Database
import Subscriptions


def logger():
  return logging.getLogger(__name__)


def HandleSeriesRequest(message):
  print "Handling SeriesRequest..."
  #
  db = Database.instance();
  response = LostSeriesProtocol_pb2.SeriesResponse()
  for showData in list(db.shows.find({"$or": [{ "value." + SHOW_IS_CANCELED: False }, { "value." + SHOW_IS_CANCELED_FIXED: False }]})):
    show = showData['value'];
    if not SHOW_IS_CANCELED_FIXED in show and show[SHOW_IS_CANCELED]:
      continue
    if SHOW_IS_CANCELED_FIXED in show and show[SHOW_IS_CANCELED_FIXED]:
      continue
    showInfo = response.shows.add()
    showInfo.title = show[SHOW_TITLE]
    showInfo.originalTitle = show[SHOW_ORIGINAL_TITLE]
    showInfo.seasonNumber = show[SHOW_LAST_SEASON_NUMBER]
    showInfo.episodeNumber = show[SHOW_LAST_EPISODE_NUMBER]
    showInfo.id = show[SHOW_ID]
    showInfo.snapshot = Snapshot.GetLatestSnapshot()
    for episodeData in list(db.episodes.find({"$and": [{"value." + SHOW_ID: show[SHOW_ID]}, {"value." + SHOW_SEASON_NUMBER: show[SHOW_LAST_SEASON_NUMBER]}]})):
      episode = episodeData['value'];
      episodeInfo = showInfo.episodes.add()
      episodeInfo.name = episode[SHOW_SEASON_EPISODE_NAME]
      episodeInfo.originalName = episode[SHOW_SEASON_SPISODE_ORIGINAL_NAME]
      episodeInfo.number = episode[SHOW_SEASON_EPISODE_NUMBER]
      episodeInfo.dateTranslate = episode[SHOW_SEASON_SPISODE_TRANSLATE_TIME].strftime("%Y-%m-%dT%H:%M:%S +04:00")
  return {"message": response, "data": None}


def HandleArtworkRequest(message):
  print "Handling ArtworkRequest..."
  #
  response = LostSeriesProtocol_pb2.ArtworkResponse()
  record = Database.instance().artworks.find_one({"$and": [{SHOW_ID: message.idShow}, {SHOW_SEASON_NUMBER: message.seasonNumber}]})
  artwork = ""
  if record:
    print message.thumbnail
    if message.thumbnail:
      artwork = record[SHOW_SEASON_ARTWORK_THUMBNAIL]
    else:
      artwork = record[SHOW_SEASON_ARTWORK]
  #
  return {"message": response, "data": artwork}


def HandleSetSubscriptionRequest(message):
  print "Handling SetSubscriptionRequest..."
  #
  subscriptions = []
  for record in message.subscriptions:
    subscriptions.append(record.id)
  Subscriptions.ChangeSubscription(message.idClient, message.token, subscriptions, message.flagUnsubscribe)
  #
  response = LostSeriesProtocol_pb2.SetSubscriptionResponse()
  response.result = True
  #
  return { "message": response, "data": None }


def HandleGetSubscriptionRequest(message):
  print "Handling HandleGetSubscriptionRequest..."
  #
  subscriptions = Subscriptions.GetSubscription(message.idClient)
  #
  response = LostSeriesProtocol_pb2.GetSubscriptionResponse()
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
      logging.debug("Packet recieved from client:")
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
  logging.config.fileConfig('logging.ini')
  logger().info("LostSeries Server started")
  #
  context = zmq.Context()
  socket = context.socket(zmq.REP)
  socket.bind("tcp://*:8500")
  MessageLoop(socket)


Main()
