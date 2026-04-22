import Config

config :aria_storage,
  storage_backend: :s3,
  bucket: System.get_env("AWS_S3_BUCKET", "uro-uploads"),
  region: System.get_env("AWS_REGION", "us-east-1"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION", "us-east-1"),
  s3: [
    scheme: "http://",
    host: System.get_env("AWS_S3_HOST", "localhost"),
    port: String.to_integer(System.get_env("AWS_S3_PORT", "7070"))
  ]
