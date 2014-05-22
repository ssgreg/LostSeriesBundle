# [SublimeLinter @python:2]
# -*- coding: utf-8 -*-
#
# Main.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

import zmq
import traceback
import time
import thread
import logging
import logging.config
#
import LostSeriesProtocol_pb2
from Storage import *
import Database
import Subscriptions
import DataBuilder


def logger():
  return logging.getLogger(__name__)


def HandleSeriesRequest(message):
  logger().debug("Handling SeriesRequest...")
  #
  db = Database.instance()
  response = LostSeriesProtocol_pb2.SeriesResponse()
  # {"$or": [{ "value." + SHOW_IS_CANCELED: False }, { "value." + SHOW_IS_CANCELED_FIXED: False }]}
  for showData in list(db.shows.find()):
    show = showData['value']
    # if not SHOW_IS_CANCELED_FIXED in show and show[SHOW_IS_CANCELED]:
    #   continue
    # if SHOW_IS_CANCELED_FIXED in show and show[SHOW_IS_CANCELED_FIXED]:
    #   continue
    episodesToSend = list(db.episodes.find({"$and": [{"value." + SHOW_ID: show[SHOW_ID]}, {"value." + SHOW_SEASON_NUMBER: show[SHOW_LAST_SEASON_NUMBER]}]}))
    year = 0
    for episodeData in episodesToSend:
      episode = episodeData['value']
      if episode[SHOW_SEASON_SPISODE_TRANSLATE_TIME].year > year:
        year = episode[SHOW_SEASON_SPISODE_TRANSLATE_TIME].year

    if year < 2012:
      continue

    response.snapshot = str(Database.getSnapshotID())
    showInfo = response.shows.add()
    showInfo.title = show[SHOW_TITLE]
    showInfo.originalTitle = show[SHOW_ORIGINAL_TITLE]
    showInfo.seasonNumber = show[SHOW_LAST_SEASON_NUMBER]
    showInfo.episodeNumber = show[SHOW_LAST_EPISODE_NUMBER]
    showInfo.id = show[SHOW_ID]

    for episodeData in episodesToSend:
      episode = episodeData['value'];
      episodeInfo = showInfo.episodes.add()
      episodeInfo.name = episode[SHOW_SEASON_EPISODE_NAME]
      episodeInfo.originalName = episode[SHOW_SEASON_SPISODE_ORIGINAL_NAME]
      episodeInfo.number = episode[SHOW_SEASON_EPISODE_NUMBER]
      episodeInfo.dateTranslate = episode[SHOW_SEASON_SPISODE_TRANSLATE_TIME].strftime("%Y-%m-%dT%H:%M:%S +04:00")
  return {"message": response, "data": None}


def HandleArtworkRequest(message):
#  logger().debug("Handling ArtworkRequest...")
  #
  record = Database.instance().artworks.find_one({"$and": [{SHOW_ID: message.idShow}, {SHOW_SEASON_NUMBER: message.seasonNumber}]})
  response = LostSeriesProtocol_pb2.ArtworkResponse()
  response.snapshot = ""
  artwork = ""
  if record:
    response.snapshot = str(record[SHOW_SEASON_ARTWORK_SNAPSHOT])
    if message.thumbnail:
      artwork = record[SHOW_SEASON_ARTWORK_THUMBNAIL]
    else:
      artwork = record[SHOW_SEASON_ARTWORK]
  #
  return {"message": response, "data": artwork}


def HandleSetSubscriptionRequest(message):
  logger().debug("Handling SetSubscriptionRequest...")
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
  logger().debug("Handling HandleGetSubscriptionRequest...")
  #
  subscriptions = Subscriptions.GetSubscription(message.idClient)
  #
  response = LostSeriesProtocol_pb2.GetSubscriptionResponse()
  for subscription in subscriptions:
    record = response.subscriptions.add()
    record.id = subscription
  #
  return {"message": response, "data": None}


def HandleGetUnwatchedSeriesRequest(message):
  logger().debug("Handling HandleGetUnwatchedSeriesRequest...")
  #
  episodes = Subscriptions.GetUnwatchedEpisodes(message.idClient)
  #
  response = LostSeriesProtocol_pb2.GetUnwatchedSeriesResponse()
  for episode in episodes:
    record = response.episodes.add()
    record.idShow = episode['idShow']
    record.numberSeason = episode['numberSeason']
    record.numberEpisode = episode['numberEpisode']
  #
  return {"message": response, "data": None}


def HandleSetUnwatchedSeriesRequest(message):
  logger().debug("Handling HandleSetUnwatchedSeriesRequest...")
  #
  episodes = []
  for record in message.episodes:
    episode = {}
    episode['idShow'] = record.idShow
    episode['numberSeason'] = record.numberSeason
    episode['numberEpisode'] = record.numberEpisode
    episodes.append(episode)
  #
  Subscriptions.SetUnwatchedEpisodes(message.idClient, episodes, message.flagRemove)
  #
  response = LostSeriesProtocol_pb2.SetUnwatchedSeriesResponse()
  response.result = True
  #
  return {"message": response, "data": None}


def HandleGetSnapshotsRequest(message):
  logger().debug("Handling HandleGetSnapshotsRequest...")
  #
  response = LostSeriesProtocol_pb2.GetSnapshotsResponse()
  #
  response.snapshotSeries = str(Database.getSnapshotID())
  #
  for artwork in list(Database.instance().artworks.find()):
    record  = response.snapshotsArtwork.add()
    record.idShow = artwork[SHOW_ID]
    record.numberSeason = artwork[SHOW_SEASON_NUMBER]
    record.snapshot = str(artwork[SHOW_SEASON_ARTWORK_SNAPSHOT])
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
    response.seriesResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.ArtworkResponse:
    response.artworkResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.SetSubscriptionResponse:
    response.setSubscriptionResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.GetSubscriptionResponse:
    response.getSubscriptionResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.GetUnwatchedSeriesResponse:
    response.getUnwatchedSeriesResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.SetUnwatchedSeriesResponse:
    response.setUnwatchedSeriesResponse.CopyFrom(message)
  elif type(message) is LostSeriesProtocol_pb2.GetSnapshotsResponse:
    response.getSnapshotsResponse.CopyFrom(message)
  #
  data = response.SerializeToString()
  return data


def DispatchMessage(message):
#  logger().debug("Dispatching a message %s" % (message))
  #
  if message.HasField("seriesRequest"):
    response = HandleSeriesRequest(message.seriesRequest)
  elif message.HasField("artworkRequest"):
    response = HandleArtworkRequest(message.artworkRequest)
  elif message.HasField("setSubscriptionRequest"):
    response = HandleSetSubscriptionRequest(message.setSubscriptionRequest)
  elif message.HasField("getSubscriptionRequest"):
    response = HandleGetSubscriptionRequest(message.getSubscriptionRequest)
  elif message.HasField("getUnwatchedSeriesRequest"):
    response = HandleGetUnwatchedSeriesRequest(message.getUnwatchedSeriesRequest)
  elif message.HasField("setUnwatchedSeriesRequest"):
    response = HandleSetUnwatchedSeriesRequest(message.setUnwatchedSeriesRequest)
  elif message.HasField("getSnapshotsRequest"):
    response = HandleGetSnapshotsRequest(message.getSnapshotsRequest)
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


def UpdateLoop():
  while (True):
    time.sleep(5 * 60)
    DataBuilder.UpdateAll()


def Main():
  logging.config.fileConfig('logging.ini')
  logger().info("LostSeries Server started")
  #
  context = zmq.Context()
  socket = context.socket(zmq.REP)
  socket.bind("tcp://*:8500")
  thread.start_new_thread(UpdateLoop, ())
  MessageLoop(socket)


Main()
