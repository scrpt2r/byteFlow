# ByteFlow

A highly optimized networking abstraction for Roblox. Built on top of buffers and custom packet routing to minimize network footprint, compress data automatically, and streamline client-server-server communication.

## API Reference

### Core Networking (Shared)

**`net.on(packetName: string, handler: function)`**
Listens for an incoming network packet.

**`net.once(packetName: string, handler: function)`**
Listens for a packet and automatically disconnects after the first trigger.

**`net.off(packetName: string, handler?: function)`**
Disconnects a specific handler from a packet. If no handler is provided, clears all connections for that packet.

**`net.fire(packetName: string, ...)`**
Fires a packet across the network boundary.
* **Client-side:** Fires to the server. `net.fire(packetName, args...)`
* **Server-side:** Fires to a specific client. Requires `Player` as the first argument. `net.fire(packetName, targetPlayer, args...)`

### Server Only

**`net.broadcast(packetName: string, ...)`**
Fires a packet to all connected clients.

**`net.fireMany(packetName: string, targets: {Player}, ...)`**
Fires a packet to a specific array of players.

**`net.fireExpect(packetName: string, expect: Player, ...)`**
Fires a packet to all clients *except* the specified player (Useful for replicating states from one client to everyone else).

### Client Only

**`net.relay(packetName: string, target: Player, ...)`**
Sends a client-to-client (c2c) packet. The server routes this securely to the target player without processing the payload.

### Cross-Server (MessagingService)

**`net.serverFire(packetName: string, ...)`**
Publishes data to all running servers across the experience via MessagingService.

**`net.serverOn(packetName: string, handler: function)`**
Subscribes to cross-server messages for the specified packet.

### Local Signals (Internal)

**`net.localFire(packetName: string, ...)`**
Fires a local signal (Client-to-Client Script or Server-to-Server Script). Does not cross the network boundary.

**`net.localOn(packetName: string, handler: function)`**
Listens for a local signal. Returns a Connection object that can be disconnected.

### Utilities

**`net.listPackets()`**
Returns a list of all registered packet definitions.

**`net.messureSize(packetName: string, ...)`**
Encodes and compresses dummy arguments to return network footprint metrics.
*Returns:* `{ raw: number, compressed: number, instances: number, ratio: number }`

## Example Usages
### Example Usages

**Require Module and Packet setup:**
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")
local constructor = require(replicatedStorage.byteflow) -- Change your path if u have a diffrent one

local net = constructor.net
local packet = constructor.packet

--// You can edit packets in packet module before return.

-- Client To Server -- if its a local script
packet.define("clientPacketName", { channel = "reliable", direction = "c2s" }) -- "c2s" means client to server.

-- Server To Client -- if its a server script
packet.define("serverPacketName", { channel = "reliable", direction = "s2c" }) -- "s2c" means server to client.
```

**Example fire and recieve (on):**
```lua
-- Client To Server 
net.fire("clientPacketName", "Hello World!") -- on local script

net.on("clientPacketName", function(player: Player, message: string) -- on server script
    print(player.Name, "says:", message)
end)

-- Server To Client
net.fire("serverPacketName", game.Players.Roblox, "Hello World!") -- on server script

net.on("serverPacketName", function(message: string) -- on local script
    print("You recieved a message from server says:", message)
end)
```

**Example local to local:**
```lua
-- Local To Local
net.localFire("localPacket", { item = "HealthPotion", amount = 3 }) -- Doesnt matter which side u on. -- You dont have to specify a packet for local
sendings.

net.localOn("localPacket", function(data) -- MUST have to be the same side as the fire came from.
    print("Updating inventory for:", data.item, "Count:", data.amount)
end)
```

