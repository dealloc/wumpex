import Config

# While testing, only show warnings.
config :logger,
  truncate: :infinity,
  console: [
    metadata: [:shard, :guild_id, :bucket]
  ],
  compile_time_purge_matching: [
    [module: Wumpex.Base.Websocket, level_lower_than: :warn],
    [module: Wumpex.Gateway, level_lower_than: :warn]
  ]

config :wumpex,
  key: "",
  buckets: 4,
  distributed: false

if File.exists?("config/.secret.exs") do
  import_config(".secret.exs")
else
  IO.warn("config/.secret.exs does not exist, empty configuration will probably fail!")
end

import_config "#{Mix.env()}.exs"
