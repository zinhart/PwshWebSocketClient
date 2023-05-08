# https://github.com/python-websockets/websockets/blob/34aaf6bcbbac62d8c605d5ba768709346ef87c6e/example/secure_server.py

#!/usr/bin/env python

# WSS (WS over TLS) server example, with a self-signed certificate

import asyncio
import pathlib
import ssl
import websockets
import sys
async def echo(websocket, path):
    async for message in websocket:
        print ("Received and echoing message: "+message, flush=True)
        await websocket.send(message)
    '''
    name = await websocket.recv()
    print(f"< {name}")

    greeting = f"Hello {name}!"

    await websocket.send(greeting)
    print(f"> {greeting}")
    '''


interface = "localhost"
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8001
ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
localhost_pem = pathlib.Path(__file__).with_name("ServerDonkey.pem")
ssl_context.load_cert_chain(localhost_pem)

start_server = websockets.serve(echo, interface, port, ssl=ssl_context)
print(F"WebSockets echo server starting at wss://{interface}:{port}/", flush=True)
asyncio.get_event_loop().run_until_complete(start_server)
print("WebSockets echo server running", flush=True)
asyncio.get_event_loop().run_forever()
