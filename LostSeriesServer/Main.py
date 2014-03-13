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


def HandleSeriesRequest(message):
  print "Handling SeriesRequest..."
  data = DataCache.Instance().GetData()
  #
  response = LostSeriesProtocol_pb2.SeriesResponse()
  for record in data:
    showInfo = response.shows.add()
    showInfo.title = record.Title
    showInfo.originalTitle = record.OriginalTitle
    showInfo.seasonNumber = record.Season
    showInfo.snapshot = Snapshot.GetLatestSnapshot()
  #  showInfo.artwork = ReadFile()
  return {"message": response, "data": None}


def HandleArtworkRequest(message):
  print "Handling ArtworkRequest..."
  data = DataCache.Instance().GetData()
  #
  response = LostSeriesProtocol_pb2.ArtworkResponse()
  response.snapshot = message.snapshot
  response.originalTitle = message.originalTitle
  #
  artwork = ""
  try:
    artwork = next(x for x in data if x.OriginalTitle == message.originalTitle).Artwork
  except:
    pass
  #
  for record in data:
    print record.OriginalTitle
#  time.sleep(random.randint(0, 2))
  return {"message": response, "data": artwork}


def HandleSetSubscriptionRequest(message):
  print "Handling SetSubscriptionRequest..."
  response = LostSeriesProtocol_pb2.SetSubscriptionResponse()
  #
  client = pymongo.MongoClient()
  db = client['lostseries-database']
  subscriptionsSection = db.subscriptions
  #
  subscriptions = []
  for record in message.subscriptions:
    subscriptions.append(record.originalTitle)
  #
#  for idc in subscriptionsSection.find({"token": message.token}):
#    subscriptions = subscriptions + idc["tags"]
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
    record.originalTitle = subscription
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
#      zeroFrame = socket.recv()
#      header = socket.recv()
      request = socket.recv()
      print "Handle!"
      #
      requestMessage = ParseData(request)
      response = DispatchMessage(requestMessage)
      #
      binaryResponse = SerializeMessage(response["message"])
#      socket.send(zeroFrame, zmq.SNDMORE)
#      socket.send(header, zmq.SNDMORE)
      if response["data"] is None:
        socket.send(binaryResponse)
      else:
        socket.send(binaryResponse, zmq.SNDMORE)
        socket.send(response["data"])

    except Exception as e:
      print "Handling run-time exception:", e
      print traceback.format_exc()
      # to remove
      return

class ServerWorker(threading.Thread):
  """ServerWorker"""
  def __init__(self, context):
    threading.Thread.__init__ (self)
    self.context = context

  def run(self):
    socket = self.context.socket(zmq.DEALER)
    socket.connect("inproc://backend")
    MessageLoop(socket)

class ServerTask(threading.Thread):
    """ServerTask"""
    def __init__(self):
        threading.Thread.__init__ (self)

    def run(self):
      context = zmq.Context()
      #
      frontend = context.socket(zmq.ROUTER)
      frontend.bind("tcp://*:8500")
      #
      backend = context.socket(zmq.DEALER)
      backend.bind("inproc://backend")
      #
      workers = []
      for i in range(5):
        worker = ServerWorker(context)
        worker.start()
        workers.append(worker)
      #
      zmq.device(zmq.QUEUE, frontend, backend)

def Main():
  print "LostSeries Server started"
  #
#  server = ServerTask()
#  server.start()
#  server.join()

  context = zmq.Context()
  socket = context.socket(zmq.REP)
  socket.bind("tcp://*:8500")
  MessageLoop(socket)


Main()
