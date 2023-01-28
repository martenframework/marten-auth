ENV["MARTEN_ENV"] = "test"

require "spec"
require "timecop"

require "marten"
require "marten/spec"

{% if env("MARTEN_SPEC_DB_CONNECTION").id == "postgresql" %}
  require "pg"
{% elsif env("MARTEN_SPEC_DB_CONNECTION").id == "mysql" %}
  require "mysql"
{% else %}
  require "sqlite3"
{% end %}

require "../src/marten_auth"
require "../src/marten_auth/spec"

require "./test_project"

def for_mysql(&)
  for_db_backends(:mysql) do
    yield
  end
end

def for_postgresql(&)
  for_db_backends(:postgresql) do
    yield
  end
end

def for_sqlite(&)
  for_db_backends(:sqlite) do
    yield
  end
end

def for_db_backends(*backends : String | Symbol, &)
  current_db_backend = ENV["MARTEN_SPEC_DB_CONNECTION"]? || "sqlite"
  if backends.map(&.to_s).includes?(current_db_backend)
    yield
  end
end

def create_user(email : String, password : String)
  user = User.new(email: email)
  user.set_password(password)
  user.save!

  user
end
