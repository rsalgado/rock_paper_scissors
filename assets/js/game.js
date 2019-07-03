let Game = {
  // Game data (status) useful for client-side tasks.
  data: {
    name: null,
    role: null,
    players: {
      guest: {},
      host: {}
    }
  },
  // Convenient reference to channel. (TODO: Remove this when done. Only for development)
  channel: null,

  /** Initialize the Game object. 
    * Establish the connection to the socket and join the channel.
    * Initialize the data properties
    * Add event handlers for channel messages/events
  */
  init(socket, gameElement) {
    if (!gameElement) { return }
    socket.connect()

    let gameName = gameElement.getAttribute("data-game-name")
    let channel = socket.channel(`games:${gameName}`)

    channel.join()
      .receive("ok", resp => {
        console.log(`Joined the channel "games:${gameName}" successfully`)

        this.channel = channel
        this.data.name = gameName
        this.data.role = resp.role
        this.data.players = resp.players
      })
      .receive("error", resp => {
        console.log("Error joining the channel", resp)
      })
  }
}

// TODO: Remove this when done. This is only for development purposes
window.Game = Game

export default Game
