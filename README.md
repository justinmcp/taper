# Taper

![License](https://img.shields.io/hexpm/l/taper) ![Hex.pm](https://img.shields.io/hexpm/v/taper) [![Build Status]()] [![Coverage]()]

Taper is a React (with SSR) and server-side-redux-like environment for
Elixir+Phoenix.

Taper is _not_ ready for production use, currently it's "all the ingredients
in a bowl, and looking like it might be a nice cake", but not even mixed
properly yet. Still, feel free to experiment.

## Installation

Add taper to your mix.exs.

```elixir
def deps do
  [
    {:taper, "~> 0.1.0"}
  ]
end
```

## Configuration

```elixir
defmodule AwesomeWeb
...
  def view do
    quote do
      ...
      import Taper.View
    end
  end
end
```

```elixir
defmodule AwesomeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :awesome
  ...
  socket "/taper", Taper.Socket, websocket: true
end
```

```elixir
config :phoenix, :template_engines, jsx: Taper.Template.Engine
```

```html
<head>
  <%= taper_meta_tag(@conn) %>
</head>
<body>
  <main role="main">
    <%= taper_render(@view_module, @view_template, assigns, class: "myclass") %>
  </main>
  <%= taper_script() %>
</body>
```

```json
  "dependencies": {
    ...
    "taper": "file:../deps/taper",
    "react": "^16.13.1",
    "react-dom": "^16.13.1"
  },
  "devDependencies": {
    "@babel/core": "^7.0.0",
    "@babel/plugin-proposal-class-properties": "^7.10.4",
    "@babel/plugin-transform-modules-commonjs": "^7.9.6",
    "@babel/plugin-transform-react-jsx": "^7.9.4",
    "@babel/preset-env": "^7.0.0",
    "@babel/preset-react": "^7.9.4",
  }
```

```javascript
import { Socket } from "phoenix";
import React from "react";
import ReactDOM from "react-dom";
import { Taper } from "taper";
import App from "./components/App";
import css from "../css/app.scss";

let taperToken = document
  .querySelector("meta[name='taper-token']")
  .getAttribute("content");
let rootComponent = document.getElementById("taper");
window.taper = new Taper(
  "/taper",
  { Socket, React, ReactDOM },
  { params: { taperToken } }
);
window.taper.connect();
window.taper.render(<App />, rootComponent);
```

## TODO

- [ ] SSR with active store state (not initial store state)
- [ ] Server side routing (with code splitting)
- [ ] Setup mix task
- [ ] Flip store ownership to make semi/persistent stores easier
- [ ] Handle errors in JSX templates
- [ ] RPC channel
- [ ] GraphQL channel
- [ ] Cleanup Ecto support
- [ ] Only send store changes to client
- [ ] ...
- [ ] A lot of tests

## Examples

Some examples can be found @ [taper-examples](https://github.com/justinmcp/taper-examples)

## License

Copyright (c) 2020 Justin McPherson

This project is licensed under the terms of the MIT license, please see the
LICENSE.md file for more details.
