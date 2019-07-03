let Game = {
  // Game data (status) useful for client-side tasks.
  // It was not necessary define these properties here, but I did it anyway for explicitness.
  data: {
    name: null,
    role: null,
    status: null,
    players: {
      guest: {},
      host: {}
    }
  },
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
    
    // Join the channel
    channel.join()
      .receive("ok", resp => {
        console.log(`Joined the channel "games:${gameName}" successfully`)
        // Update the Game's local state
        this.channel = channel
        this.data.name = gameName
        this.data.role = resp.role
        this.data.players = resp.players
        this.data.status = resp.status
      })
      .receive("error", resp => {
        console.log("Error joining the channel", resp)
      })

    // Register callbacks
    // NOTE:  Notice I used lambdas wrapping the calls here instead of passing the callbacks directly.
    //        That's because `this` wouldn't be bound to this Game object if I pass the callback functions.
    channel.on("status_update", payload => this.onStatusUpdate(payload))
    channel.on("game_finished", payload => this.onGameFinished(payload))
  },

  /** Make choice (i.e. "rock") as the current user */
  choose(choice) {
      this.channel.push("choose", {choice})
  },

  // Callbacks

  /** This function will be called when the receiving a status update */
  onStatusUpdate({status}) {
    this.data.status = status
    console.log(`New status: "${status}"`)
  },

  /** This function will be called when receiving a notification of the game being finished. */
  onGameFinished(state) {
    console.log(`Game finished!. Winner is: ${state.winner}`)

    let otherPlayerRole = this.data.role === "host" ? "guest" : "host"
    let otherPlayer = this.data.players[otherPlayerRole]
    let yourChoice = state.choices[this.data.role]
    let theirChoice = state.choices[otherPlayerRole]

    if (state.winner === "tie") {
      console.log(`You are tied with ${otherPlayer.name}. Both chose "${yourChoice}"`)
    }
    else if (state.winner === this.data.role) {
      console.log(`You are the winner with "${yourChoice}". ${otherPlayer.name} lost with "${theirChoice}"`)
    }
    else {
      console.log(`You lost with "${yourChoice}". ${otherPlayer.name} is the winner with "${theirChoice}". `)
    }
  },
}

// TODO: Remove this when done. This is only for development purposes
window.Game = Game

export default Game
