#!/usr/bin/env python

import asyncio
import websockets
import os
import sys

async def echo_cookie(websocket, path):
    print(path)
    print(websocket.__dir__())
    print(websocket.request_headers)
    print(websocket.response_headers)
    print(websocket.origin)
    #print(websocket.cookie)
    async for message in websocket:
        print ("Received and echoing message: "+message, flush=True)
        await websocket.send(message)

interface = "0.0.0.0"
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
start_server = websockets.serve(echo_cookie, interface, port=port)

print(F"WebSockets echo server starting at ws://{interface}:{port}/", flush=True)
asyncio.get_event_loop().run_until_complete(start_server)

print("WebSockets echo server running", flush=True)
asyncio.get_event_loop().run_forever()