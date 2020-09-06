import Config

# While testing, only show warnings.
config :logger,
  compile_time_purge_matching: [
    [application: :wumpex, level_lower_than: :warn]
  ]

config :wumpex,
  key: "DUMMY-TEST-TOKEN",
  endpoint: "http://localhost:8081"
