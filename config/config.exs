import Config

config :wumpex,
  key: ""

import_config(".secret.exs")
import_config "#{Mix.env()}.exs"
