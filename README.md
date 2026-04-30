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
