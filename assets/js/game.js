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
      choicesEnabled() {
        let waitingChoices = this.status === "waiting_choices"
        let waitingMeAsHost = this.status === "waiting_host_choice" && this.role === "host"
        let waitingMeAsGuest = this.status === "waiting_guest_choice" && this.role === "guest"
        return waitingChoices || waitingMeAsHost || waitingMeAsGuest
      },

      otherPlayerRole() {
        return this.role === "host" ? "guest" : "host"
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

      finishGame(state) {
        this.winner = state.winner
        this.choices = state.choices

        let otherPlayerRole = this.otherPlayerRole
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
          case "finished":  return "Game finished!"
          default:  return "Invalid state"
        }
      }
    },
  })

  let choiceRow = Vue.component('choice-row', {
    props: {'title': String, 'choice': String, 'enabled': Boolean},
    template: "#choice-row-template",
    methods: {
      select(choice) {
        if (!this.enabled) { return }
        this.$emit("selection", choice)
      }
    }
  })

  window.app = app
}


// TODO: Remove this when done. This is only for development purposes
window.Game = Game

export {Game, createVueApp}
