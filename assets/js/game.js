let Game = {
  init(socket, gameElement) {
    if (!gameElement) { return }
    socket.connect()

    let gameId = gameElement.getAttribute("data-game-name")
    let channel = socket.channel(`games:${gameId}`)

    channel.join()
      .receive("ok", resp => console.log(`Joined channel games:${gameId} successfully`))
      .receive("error", resp => console.log("Error joining the channel", resp))

    // // TODO:  This is still in progress. Get it working and import this file in app.js when you're done.
    // //        Currently this code is just for reference (to copy and manually run from the browser's console)
    // let role = ""
    // let channel = socket.channel("game:FiCtIcIoUs", {"role": role})
    // channel.join()
    //   .receive("ok", resp => { console.log("Joined successfully", resp) })
    //   .receive("error", resp => { console.log("Unable to join", resp) })

    // channel.on("update_state", ({state}) => console.log(`New state: ${state}`))
    // channel.on("final_status", (status) => console.log("Final Status:", status))
  }
}

export default Game