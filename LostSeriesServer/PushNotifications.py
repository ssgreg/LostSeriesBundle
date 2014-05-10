# -*- coding: utf-8 -*-
# 
# PushNotifications.py
# LostSeriesServer
#
#  Created by Grigory Zubankov.
#  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
#

from apns import *


def Do(token_hex, text):
  cert_path = 'LostSeriesCert.pem'
  key_path = 'pkey.pem'
  apns = APNs(use_sandbox=True, cert_file=cert_path, key_file=key_path)
  #
  payload = Payload(alert=text, sound="default", badge=1)
  apns.gateway_server.send_notification(token_hex, payload)


# test
Do('99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd', 'Greg')