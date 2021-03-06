# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ex_aws,
  dynamodb: [
    port: "8000",
    scheme: "http://",
    host: "localhost"
  ]

config :api_accounts, ApiAccounts.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: "${MAILGUN_API_KEY}",
  domain: "${MAILGUN_DOMAIN}"

config :api_accounts, migrate_on_start: false

import_config "#{Mix.env()}.exs"
