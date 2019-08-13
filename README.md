# RockPaperScissors

This is a small implementation of the classic _rock, paper, scissors_ game using Phoenix framework and Vue.js. The application, allows to the players to create games as **host**s and invite another player as a **guest** to play with. Thanks to Phoenix channels, the players can get updates in the status in real-time and see the final result when both of them have made their choices.

The games are held in-memory and live for 10 minutes, independently of whether they're finished or not. A user doesn't sign up, and only "signs in" by entering its name to create a session, which is destroyed when said user logs out.

For simplicity, the Vue.js front-end logic is only for the game part of the application, while the rest of the UI is handled with Phoenix views and templates. As this is not a SPA and only includes the necessary Vue.js for the game section, everything is managed as part of the Phoenix app; Vue is an npm dependency, and there are no single-file components (SFCs), instead the Vue HTML and templates are inside a Phoenix Eex template.

See the **Code Overview** section below for more details on how this works currently.


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
The core functionality outside of Phoenix is in the `lib/rock_paper_scissors` directory;  it is the **context** of this app; it's API with which the Phoenix code will interact with is exposed directly in the `lib/rock_paper_scissors.ex` file, whose module has top level functions for creating, finding, listing and stopping games as well as a helper function for generating random sequences of alphanumeric characters (it will be useful for game names/ids and players' ids).

#### What's in a game?
The app supports many games concurrently and independently, all running in-memory. In order to achieve that, it represents each game as a GenServer process, under a dynamic supervisor (`RockPaperScissors.GamesSupervisor` defined in `application,ex`) and identified by a name/id in a registry (`RockPaperScissors.GamesRegistry` also defined in `application.ex`). That way we can easily manage the different games under a supervision tree and search for them by name, instead of having only their pid.

The code for the GenServer for representing games is in the module `RockPaperScissors.GameServer` in `lib/rock_paper_scissors/game_server.ex`. In addition to the usual GenServer functions and those required for the supervisor (`child_spec`, `start_link` and `init`), it exposes a small API (GenServer client functions) to interact with the game state. The functions include getters for `state`, `name`, `status`, `choices`, `player`, and other, as well as functions for setting guest and host (`set_guest`, `set_host`) and choosing an option for a given player role (`choose`).

However, the `GameServer` is mostly a wrapper and the core logic as well as the state are ultimately managed inside the `RockPaperScissors.GameState` module (at `lib/rock_paper_scissors/game_state.ex`).
`GameState` defines a struct with the main parts of a game, like `name`, `status`, `players`, `choices`, among others; as well as functions for modifying the different parts of the game state and update the status accordingly (these are the functions wrapped by `GameServer`). The functions allow to set the guest and host, make choices and update the status. More specifically, when setting one of the players, or the choice of one of them, not only is their corresponding field updated but also, the game's status is recalculated and updated to reflect the changes made.

Although the app doesn't use a state machine, the different status and the way a game goes from one to another with each action, can be modeled roughly using a state machine, although some status are more internal and transitional. The possible status are `:missing_players`, `:missing_guest`, `:missing_host` and `:players_ready` for the players part, and `:waiting_choices`, `:waiting_guest_choice`, `:waiting_host_choice` and `:choices_ready` for the choices part; and finally, there's the `:finished` status. As for the possible choices to make for a given role, they are: `:none`, `:rock`, `:paper`, `:scissors`. See the module file for more details; also, feel free to play with it in IEx.


### Phoenix web app
The structure of Phoenix web app follows the framework's conventions; it has a simple router with a small plug function for handling tokens (it will be useful for channels), and only a few routes for games and sessions. As you can see from the routes the controllers for games and sessions are respectively `GameController` and `SessionController` (in the `RockPaperScissorsWeb` namespace); which implement the actions for creating, viewing and joining games as well as creating and destroying sessions (signing in and out of the app). There are also views and templates corresponding the controllers' actions, following the framework's conventions.

For session handling (authentication and authorization), the `SessionController` shows a simple form where the user enters its name and a new `Player` struct with a random alphanumeric id and the user's name is created and put in the connection's session (normally in a cookie) under the key `:current_user`. Signing out, just removes that entry from the connection's session. As mentioned, there's no sign up, and player's data is not persisted and only kept in-memory and in the session's cookies. Put in other words: sessions are temporary.


#### Game controller, templates and forms
The game's web functionality is mediated by the `GameController`. First of all, it defines a plug function `authorize_user` to handle basic authorization of the users to the game: if they haven't signed in, they're redirected to the path for creating new sessions, preventing them from performing any action.

For convenience, the user's `Player` struct stored in the session is injected into all controller's actions as a third parameter. The available actions are: `new` for showing the forms to create or join games; `create` for game creation after the corresponding form is submitted, setting the current user's player as the host and, redirecting to that game's path; `join` for joining an existing game after the corresponding form is submitted, setting the current user's player as guest, and redirecting to the game's path; and finally, `show` for showing the game if the current user's player is one of the game's players (either guest or host).

The `show` action is where the game UI is. It renders the `game/show.html.eex` template, where the Vue.js application component and template resides, too. It contains basically a main `div` (`#game`) with a `data-game-name` attribute containing the game's name and the Vue app's root (`.game`), which itself contains a couple of `choice-group` components: one for the current user and another for the opponent. For convenience and simplicity, the template for the components is defined here in an HTML `template` tag (`#choice-group-template`).


### Vue.js game logic and Phoenix channels
Knowing already where the template part of the Vue.js is from the previous section, the other part of the app, the Javascript code, is what this section is about. The necessary JS is at `assets/js` and more specifically most of the code is at `game.js`, given that `app.js` acts as a higher-level file where the `socket`, `game` and CSS styles are imported.

`game.js` entry point is `createVueApp` where the connection to the Phoenix socket is made, a new channel is opened using the game's name as sub-topic, and the code for both `choiceGroup` and `app` (root Vue instance) components is defined.

The `app` Vue instance has fields for the different aspects of the game, mirroring similar fields in the backend's `GameState`, as well as a couple of computed properties for convenience a lifecycle hook to join the channel when the instance is created, and methods for choosing and option and handling status updates and game finalization, which are triggered when a message comes through the channel; see the `created` function to get more details on how the channel is integrated with the Vue instance.

The messages/events `"status_update"` and `"game_finished"`, are how the changes in the game's status (and state in general) are propagated to the front-end in real-time. At the other side of the channel, its backend functionality is implemented at `channels/user_socket.ex` and `channels/game_channel.ex`. The initial authentication of the socket being performed by `assets/js/socket.js` at the front-end and `channels/user_socket.ex` at the back-end; while using the common strategy of putting the token (`window.userToken`) in the layout's template (`templates/layout/app.html.eex`) inside a `script` tag.

Finally, at `channels/game_channel.ex` there are the usual Phoenix channel callback for joining a channel with a given topic, keeping necessary state info at the `socket`; programming the initial status update, scheduling the game to stop after 10 minutes and sending the initial reply. The file's module also defines callbacks for handling the `"choose"` messages from the channel as well as other callbacks for internal OTP messages; those callbacks also take care of broadcasting the messages to the client JS code (front-end).
