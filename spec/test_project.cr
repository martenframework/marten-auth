require "./test_project/**"

ENV_SETTINGS_FILENAME = ".spec.env.json"

if File.exists?(ENV_SETTINGS_FILENAME)
  env_settings = Hash(String, Int32 | String).from_json(File.read(ENV_SETTINGS_FILENAME))
else
  env_settings = Hash(String, Int32 | String).new
end

Marten.configure :test do |config|
  config.secret_key = "__insecure_#{Random::Secure.random_bytes(32).hexstring}__"

  config.installed_apps = [
    MartenAuth::App,
    TestApp,
  ]

  for_mysql do
    config.database do |db|
      db.backend = :mysql
      db.name = env_settings["MYSQL_DEFAULT_DB_NAME"].as(String)
      db.user = env_settings["MYSQL_DB_USER"].as(String)
      db.password = env_settings["MYSQL_DB_PASSWORD"].as(String)
      db.host = env_settings["MYSQL_DB_HOST"].as(String)
    end
  end

  for_postgresql do
    config.database do |db|
      db.backend = :postgresql
      db.name = env_settings["POSTGRESQL_DEFAULT_DB_NAME"].as(String)
      db.user = env_settings["POSTGRESQL_DB_USER"].as(String)
      db.password = env_settings["POSTGRESQL_DB_PASSWORD"].as(String)
      db.host = env_settings["POSTGRESQL_DB_HOST"].as(String)
    end
  end

  for_sqlite do
    config.database do |db|
      db.backend = :sqlite
      db.name = ":memory:"
    end
  end

  config.auth.user_model = User
end
