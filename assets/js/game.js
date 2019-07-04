import Vue from "vue/dist/vue.esm.js"


let createVueApp = (socket, rootElement) => {
  socket.connect()
  let gameName = document.querySelector("#game").getAttribute("data-game-name")
  let channel = socket.channel(`games:${gameName}`)

  let app = new Vue({
    el: rootElement,
    data: {
      messageText: "",
      name: gameName,
      choice: null,
      role: null,
      status: null,
      winner: null,
      players: {
        guest: {},
        host: {}
      }
    },

    created() {
      // Join the channel
      channel.join()
        .receive("ok", resp => {
          console.log(`Joined the channel "games:${gameName}" successfully`)
          // Update the local state
          this.name = gameName
          this.role = resp.role
          this.players = resp.players
          this.status = resp.status
          this.messageText = this.messageForStatus(this.status)
        })
        .receive("error", resp => {
          console.log("Error joining the channel", resp)
        })

      channel.on("status_update", payload =>  this.updateStatus(payload))
      channel.on("game_finished", payload => this.finishGame(payload))
    },

    methods: {
      /** Make choice (i.e. "rock") as the current user */
      choose(choice) {
        channel.push("choose", {choice})
        this.choice = choice
      },

      /** This function will be called when the receiving a status update */
      updateStatus({status}) {
        this.status = status
        console.log(`New status: "${status}"`)
        this.messageText = this.messageForStatus(status)
      },

      finishGame(state) {
        this.winner = state.winner
        this.messageText = `Game finished!. Winner is: ${state.winner}`

        let otherPlayerRole = this.role === "host" ? "guest" : "host"
        let otherPlayer = this.players[otherPlayerRole]
        let yourChoice = state.choices[this.role]
        let theirChoice = state.choices[otherPlayerRole]
    
        if (state.winner === "tie") {
          this.messageText = `You are tied with ${otherPlayer.name}. Both chose "${yourChoice}"`
        }
        else if (state.winner === this.role) {
          this.messageText = `You are the winner with "${yourChoice}". ${otherPlayer.name} lost with "${theirChoice}"`
        }
        else {
          this.messageText = `You lost with "${yourChoice}". ${otherPlayer.name} is the winner with "${theirChoice}". `
        }
      },

      messageForStatus(status) {
        switch (status) {
          case null:  return "Starting game..."
          case "missing_guest": return "Waiting for guest to join"
          case "missing_host":  return "Waiting for host to join"
          case "waiting_choices": return "Waiting for players to make their choices"
          case "waiting_host_choice": return "Waiting for host to choose"
          case "waiting_guest_choice":  return "Waiting for guest to choose"
          case "finished":  return "Game finished! Waiting for more details..."
          default:  return "Invalid state"
        }
      }
    },
  })

  window.app = app
}


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

export {Game, createVueApp}
