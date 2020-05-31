import Config

# While testing, only show warnings.
config :logger,
  compile_time_purge_matching: [
    [module: Wumpex.Base.Websocket, level_lower_than: :warn],
    [module: Wumpex.Gateway.EventHandler, level_lower_than: :warn]
  ]

config :wumpex,
  key: ""

import_config(".secret.exs")
import_config "#{Mix.env()}.exs"
