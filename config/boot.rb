# Common boot for every entrypoint (bin/sync, bin/digest, etc.).
# Loads .env in development, opens the DB connection, and requires app/.

require "bundler/setup"
require "active_record"
require "active_support/all"
require "yaml"
require "erb"

ENV["APP_ENV"] ||= "development"

if ENV["APP_ENV"] == "development"
  begin
    require "dotenv"
    Dotenv.load
  rescue LoadError
    # dotenv is dev-only; ignore in production
  end
end

# Connect to Postgres. Same config file that `standalone_migrations` reads.
config_path = File.expand_path("../db/config.yml", __dir__)
db_config = YAML.safe_load(ERB.new(File.read(config_path)).result, aliases: true)[ENV["APP_ENV"]]
ActiveRecord::Base.establish_connection(db_config)

# Configure the LLM client.
require "ruby_llm"
RubyLLM.configure do |c|
  c.openai_api_key = ENV["OPENAI_API_KEY"]
  c.xai_api_key = ENV["XAI_API_KEY"]
end

# Eager-load app/.
APP_ROOT = File.expand_path("..", __dir__)
%w[
  app/models
  app/services
  app/mailers
].each do |dir|
  Dir[File.join(APP_ROOT, dir, "**/*.rb")].sort.each { |f| require f }
end
