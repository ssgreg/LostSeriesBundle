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
  return [x.strip() for x in idClient.split(',')]


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
      'ids_show': subscriptions
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
      'ids_show': subscriptionsNew
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
    logger().info('There is no subscription with with id')
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
#LogCurrentSubscriptions()
#GetSubscription(' 36618141-EEA7-4D02-99FA-6D20CB94EDE5')
