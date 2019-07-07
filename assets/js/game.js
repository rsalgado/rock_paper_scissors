import Vue from "vue/dist/vue.esm.js"


let createVueApp = (socket, rootElement) => {
  // Connect to socket
  socket.connect()
  // Fetch the game's name from element attribute, and use it to build the channel's topic
  let gameName = document.querySelector("#game").getAttribute("data-game-name")
  let channel = socket.channel(`games:${gameName}`)

  // This is the code for the <choice-group> component
  let choiceGroup = Vue.component('choice-group', {
    template: "#choice-group-template",
    props: {
      title: String,
      choice: String,
      enabled: Boolean,
      role: String,
      winner: String
    },

    data() {
      return {
        options: [
          {name: "rock", icon: "🤜"}, 
          {name: "paper", icon: "✋"},
          {name: "scissors", icon: "✌"}
        ]
      }
    },

    computed: {
      isWinnersRow() { return this.role === this.winner },
    },

    methods: {
      select(choice) {
        if (!this.enabled) { return }
        this.$emit("selection", choice)
      }
    }
  })

  // This is the code of the main (root) Vue instance
  let app = new Vue({
    el: rootElement,
    data: {
      messageText: "",
      name: gameName,
      role: null,
      status: null,
      winner: null,
      players: {
        guest: {},
        host: {}
      },
      choices: {
        guest: null,
        host: null
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
          this.winner = resp.winner
          this.choices = resp.choices
          this.messageText = this.messageForStatus(this.status)
        })
        .receive("error", resp => {
          console.log("Error joining the channel", resp)
        })

      channel.on("status_update", payload =>  this.updateStatus(payload))
      channel.on("game_finished", payload => this.finishGame(payload))
    },

    computed: {
      /** Determine whether the user can perform choices */
      choicesEnabled() {
        let waitingChoices = this.status === "waiting_choices"
        let waitingMeAsHost = this.status === "waiting_host_choice" && this.role === "host"
        let waitingMeAsGuest = this.status === "waiting_guest_choice" && this.role === "guest"
        return waitingChoices || waitingMeAsHost || waitingMeAsGuest
      },

      /** Get the opponent's info in a single object struct for convenience */
      opponent() {
        let result = {}
        result.role = this.role === "host" ? "guest" : "host"
        result.name = this.players[result.role].name
        result.choice = this.choices[result.role]

        return result
      }
    },

    methods: {
      /** Make choice (i.e. "rock") as the current user */
      choose(choice) {
        channel.push("choose", {choice})
        this.choices[this.role] = choice
      },

      /** This function will be called when the receiving a status update */
      updateStatus({status}) {
        this.status = status
        console.log(`New status: "${status}"`)
        this.messageText = this.messageForStatus(status)
      },

      /** This method is to be run when the game finishes and the corresponding event is sent from the channel */
      finishGame({status, winner, choices, players}) {
        this.status = status
        this.winner = winner
        this.choices = choices
        this.players = players
        this.messageText = this.messageForStatus(status)
      },

      /** Helper function to provide a descriptive message, given a game status */
      messageForStatus(status) {
        switch (status) {
          default:  return "Invalid state"
          case null:  return "Starting game..."
          case "missing_guest": return "Waiting for guest to join"
          case "missing_host":  return "Waiting for host to join"
          case "waiting_choices": return "Waiting for players to make their choices"
          case "waiting_host_choice": return "Waiting for host to choose"
          case "waiting_guest_choice":  return "Waiting for guest to choose"
          case "finished":
            let yourChoice = this.choices[this.role]
            if (this.winner === "tie")
              return `You are tied with ${this.opponent.name}. Both chose "${yourChoice}"`
            else if (this.winner === this.role)
              return `You are the winner with "${yourChoice}". ${this.opponent.name} lost with "${this.opponent.choice}"`
            else
              return `You lost with "${yourChoice}". ${this.opponent.name} is the winner with "${this.opponent.choice}"`
        }
      }
    },
  })

  // TODO: Remove this when done, as it only for development purposes to play on the browser's console
  window.app = app
}

export {createVueApp}
