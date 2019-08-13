# RockPaperScissors

This is a small implementation of the classic _rock, paper, scissors_ game using Phoenix framework and Vue.js. The application, allows to the players to create games as hosts and invite another player as a guest to play with. Thanks to Phoenix channels, the players can get updates in the status in real-time and see the final result when both of them have made their choices.

The games are held in-memory and live for 10 minutes, independently of whether they're finished or not. A user doesn't sign up, and only "signs in" by entering its name to create a session, which is destroyed when said user logs out.

For simplicity, the Vue.js front-end logic is only for the game part of the application, while the rest of the UI is handled with Phoenix views and templates. As this is not a SPA and only includes the necessary Vue.js for the game section, everything is managed as part of the Phoenix app; Vue is an npm dependency, and there are no single-file components (SFCs), instead the Vue HTML and templates are inside a Phoenix Eex template.

See the *Code Overview* section below for more details on how this works currently.


## Getting started

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix


## Code Overview

### Backend & business logic
The core functionality outside of Phoenix is in the `lib/rock_paper_scissors` directory;  it is the *context* of this app; it's API with which the Phoenix code will interact with is exposed directly in the `lib/rock_paper_scissors.ex` file, whose module has top level functions for creating, finding, listing and stopping games as well as a helper function for generating random sequences of alphanumeric characters (it will be useful for game names/ids and players' ids).

#### What's in a game?
The app supports many games concurrently and independently, all running in-memory. In order to achieve that, it represents each game as a GenServer process, under a dynamic supervisor (`RockPaperScissors.GamesSupervisor` defined in `application,ex`) and identified by a name/id in a registry (`RockPaperScissors.GamesRegistry` also defined in `application.ex`). That way we can easily manage the different games under a supervision tree and search for them by name, instead of having only their pid.

The code for the GenServer for representing games is in the module `RockPaperScissors.GameServer` in `lib/rock_paper_scissors/game_server.ex`. In addition to the usual GenServer functions and those required for the supervisor (`child_spec`, `start_link` and `init`), it exposes a small API (GenServer client functions) to interact with the game state. The functions include getters for `state`, `name`, `status`, `choices`, `player`, and other, as well as functions for setting guest and host (`set_guest`, `set_host`) and choosing an option for a given player role (`choose`).

However, the `GameServer` is mostly a wrapper and the core logic as well as the state are ultimately managed inside the `RockPaperScissors.GameState` module (at `lib/rock_paper_scissors/game_state.ex`).
`GameState` defines a struct with the main parts of a game, like `name`, `status`, `players`, `choices`, among others; as well as functions for modifying the different parts of the game state and update the status accordingly (these are the functions wrapped by `GameServer`). The functions allow to set the guest and host, make choices and update the status. More specifically, when setting one of the players, or the choice of one of them, not only is their corresponding field updated but also, the game's status is recalculated and updated to reflect the changes made.

Although the app doesn't use a state machine, the different status and the way a game goes from one to another with each action, can be modeled roughly using a state machine, although some status are more internal and transitional. The possible status are `:missing_players`, `:missing_guest`, `:missing_host` and `:players_ready` for the players part, and `:waiting_choices`, `:waiting_guest_choice`, `:waiting_host_choice` and `:choices_ready` for the choices part; and finally, there's the `:finished` status. As for the possible choices to make for a given role, they are: `:none`, `:rock`, `:paper`, `:scissors`. See the module file for more details; also, feel free to play with it in IEx.


### Phoenix web app
TODO

#### Game controller, templates and forms


### Vue.js game logic
TODO
