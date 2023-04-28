#!/usr/bin/env python3

# websocket proxy

import argparse
import asyncio
import websockets


async def forward(websocket, path):
    '''Called whenever a new connection is made to the server'''

    url = REMOTE_URL + path
    async with websockets.connect(url) as ws:
        taskA = asyncio.create_task(clientToServer(ws, websocket))
        taskB = asyncio.create_task(serverToClient(ws, websocket))

        await taskA
        await taskB


async def clientToServer(ws, websocket):
    async for message in ws:
        print(F"Client to Server: {message}")
        await websocket.send(message)


async def serverToClient(ws, websocket):
    async for message in websocket:
        print(F"Server To Client: {message}")
        await ws.send(message)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='websocket proxy.')
    parser.add_argument('--host', help='Host to bind to.',
                        default='localhost')
    parser.add_argument('--port', help='Port to bind to.',
                        default=8000)
    parser.add_argument('--remote_url', help='Remote websocket url',
                        default='ws://localhost:8767')
    args = parser.parse_args()

    REMOTE_URL = args.remote_url
    print(F"(+) Proxy server started on ws://{args.host}:{args.port}")
    print(F"(+) Proxy server forwarding to {args.remote_url}")
    start_server = websockets.serve(forward, args.host, args.port)

    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()