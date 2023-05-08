#!/usr/bin/env python

# WSS (WS over TLS) client example, with a self-signed certificate

import asyncio
import pathlib
import ssl
import websockets

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)

#ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
localhost_pem = pathlib.Path(__file__).with_name("ServerDonkey.pem")
print(localhost_pem)
ssl_context.load_verify_locations(localhost_pem)

async def hello():
    uri = "wss://localhost:8002"
    async with websockets.connect(
        uri, ssl=ssl_context
    ) as websocket:
        #name = input("What's your name? ")

        await websocket.send('Waffles')
        print(f"> {name}")

        greeting = await websocket.recv()
        print(f"< {greeting}")

asyncio.get_event_loop().run_until_complete(hello())