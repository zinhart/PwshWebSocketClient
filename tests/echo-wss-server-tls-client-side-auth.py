# https://github.com/python-websockets/websockets/blob/34aaf6bcbbac62d8c605d5ba768709346ef87c6e/example/secure_server.py

#!/usr/bin/env python

# WSS (WS over TLS) server example, with a self-signed certificate

import asyncio
import pathlib
import ssl
import websockets
import sys
import argparse

async def echo(websocket, path):
    print(websocket)
    async for message in websocket:
        print ("Received and echoing message: "+message, flush=True)
        await websocket.send(message)


parser = argparse.ArgumentParser()
parser.add_argument('-i','--interface', help='Interface to listen on', default='localhost')
parser.add_argument('-p','--port', help='Port to listen on', default=8002)
parser.add_argument('-s','--serverpem', help='Path to Server PEM', required=True)
parser.add_argument('-c','--clientcertificate', help='Path to client authorized to use this webserver', required=True)
args = parser.parse_args()

interface = args.interface
port = args.port
server_pem = pathlib.Path(__file__).with_name(args.serverpem)
client_certificate = pathlib.Path(__file__).with_name(args.clientcertificate)
print(interface)
print(port)
print(server_pem)
print(client_certificate)



#ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.verify_mode = ssl.CERT_REQUIRED
ssl_context.load_verify_locations(client_certificate, server_pem) # should supply a pem file here
ssl_context.load_cert_chain(server_pem)

start_server = websockets.serve(echo, interface, port, ssl=ssl_context)
print(F"WebSockets echo server starting at wss://{interface}:{port}/", flush=True)
asyncio.get_event_loop().run_until_complete(start_server)
print("WebSockets echo server running", flush=True)
asyncio.get_event_loop().run_forever()
