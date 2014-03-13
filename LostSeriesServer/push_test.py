from apns import *

cert_path = '/Users/igreg/Documents/Certificates/LostSeriesCert.pem'
key_path = '/Users/igreg/Documents/Certificates/pkey.pem'

token_hex = '99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd'

apns = APNs(use_sandbox=True, cert_file=cert_path, key_file=key_path)

payload = Payload(alert="Hello World!", sound="default", badge=1)

apns.gateway_server.send_notification(token_hex, payload)
