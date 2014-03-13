import zmq

ctx = zmq.Context()
client = ctx.socket(zmq.DEALER)
client.connect('inproc://aaa')
server = ctx.socket(zmq.ROUTER)
server.bind('inproc://aaa')
client.send_multipart([b'', b'123', b'abc'])

msg = server.recv_multipart()
print(msg)