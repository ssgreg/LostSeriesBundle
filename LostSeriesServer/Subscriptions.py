# -*- coding: utf-8 -*-
# 
# Subscriptions.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

#
import pymongo
import datetime
import logging
import logging.config
#
import Database


def logger():
  return logging.getLogger(__name__)


def ParseIdClient(idClient):
  if isinstance(idClient, basestring):
    return [x.strip() for x in idClient.split(',')]
  else:
    return idClient


def FindSubscriptionsRecord(idClient):
  cdid = []
  for id in ParseIdClient(idClient):
    cdid.append({"cdid":id})
  #
  results = list(Database.instance().subscriptions.find({"$or":cdid}))
  if results:
    return results[0]
  else:
    return None


def GetUnwatchedEpisodes(idClient):
  record = FindSubscriptionsRecord(idClient)
  if not record:
    []
  #
  return record['unwatched']


def AddUnwatchedEpisodes(episodes):
  logger().info("Adding unwatched epidodes to all clients...")
  #
  for record in list(Database.instance().subscriptions.find()):
    ChangeUnwatchedEpisodes(record['cdid'], episodes)


def ChangeUnwatchedEpisodes(idClient, episodes, remove = False):
  logger().info('Changing unwatched episodes for client {} with flag={}...'.format(idClient, remove))
  #
  record = FindSubscriptionsRecord(idClient)
  if not record:
    return
  #
  cdid = ParseIdClient(idClient)
  cdid.extend(record['cdid'])
  record['cdid'] = list(set(cdid))
  #
  unwatcheds = []
  if 'unwatched' in record:
    unwatcheds = record['unwatched']
  #
  for episode in episodes:
    # skip episode not in client subscription
    if not episode['ID'] in record['ids_show']:
      continue
    unwatched = \
    {
      'idShow': episode['ID'],
      'numberSeason': episode['SeasonNumber'],
      'numberEpisode': episode['EpisodeNumber']
    }
    if remove:
      if unwatched in unwatcheds:
        logger().info('Removed unwatched episode {}'.format(unwatched))
        unwatcheds.remove(unwatched)
    else:
      # add only new episodes
      if not unwatched in unwatcheds:
        logger().info('New unwatched episode {}'.format(unwatched))
        unwatcheds.append(unwatched)
    #
    record['unwatched'] = unwatcheds
  #
  Database.instance().subscriptions.remove({'_id': record['_id']})
  Database.instance().subscriptions.insert(record)


def ChangeSubscription(idClient, tokenDevice, subscriptions, unsubcribe = False):
  logger().info('Changing subscription {} flag={}...'.format(subscriptions, unsubcribe))
  #
  record = FindSubscriptionsRecord(idClient)
  if not record:
    #
    if unsubcribe:
      return
    #
    record = \
    {
      'cdid': ParseIdClient(idClient),
      'tokens': [tokenDevice],
      'date': datetime.datetime.utcnow(),
      'ids_show': subscriptions,
      'unwatched': []
    }
    logger().info('New client: {}'.format(record))
    Database.instance().subscriptions.insert(record)
  else:
    #
    subscriptionsNew = record['ids_show']
    for subsription in subscriptions:
      if unsubcribe and subsription in subscriptionsNew:
        subscriptionsNew.remove(subsription)
      if not unsubcribe:
        subscriptionsNew.append(subsription)
    subscriptionsNew = list(set(subscriptionsNew))
    #
    cdid = ParseIdClient(idClient)
    cdid.extend(record['cdid'])
    cdid = list(set(cdid))
    #
    tokens = record['tokens']
    if not tokenDevice in tokens:
      tokens.append(tokenDevice)
    #
    recordNew = \
    {
      'cdid': cdid,
      'tokens': tokens,
      'date': datetime.datetime.utcnow(),
      'ids_show': subscriptionsNew,
      'unwatched': record['unwatched']
    }
    #
    logger().info('Update client: {}'.format(recordNew))
    Database.instance().subscriptions.remove({'_id': record['_id']})
    Database.instance().subscriptions.insert(recordNew)


def GetSubscription(idClient):
  logger().info('Getting subscription for client {}...'.format(idClient))
  #
  record = FindSubscriptionsRecord(idClient)
  if record:
    logger().info('Subscription found: {}'.format(record))
    return record['ids_show']
  else:
    logger().info('There is no subscription with id')
    return []


def LogCurrentSubscriptions():
  logger().info("Logging current subscriptions...")
  #
  for record in list(Database.instance().subscriptions.find()):
    logger().info("{}".format(record))
    #
  logger().info("Loggind finished")

# test
#logging.config.fileConfig('logging.ini')
#Database.instance().subscriptions.drop()
#ChangeSubscription(' 36618141-EEA7-4D02-99FA-6D20CB94EDE5', '99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd', [u'157', u'154'], False)

#GetSubscription(' 36618141-EEA7-4D02-99FA-6D20CB94EDE5')
#ChangeUnwatchedEpisodes('u36618141-EEA7-4D02-99FA-6D20CB94EDE5', [{'ID':u'207', 'SeasonNumber':1, 'EpisodeNumber':1}])

#AddUnwatchedEpisodes([{'ID':u'207', 'SeasonNumber':1, 'EpisodeNumber':2}])
#LogCurrentSubscriptions()
#print GetUnwatchedEpisodes(' 36618141-EEA7-4D02-99FA-6D20CB94EDE5')