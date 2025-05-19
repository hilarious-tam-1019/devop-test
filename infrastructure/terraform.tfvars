region = "ap-southeast-1"

name = "devop-test"

availability_zones = [
  "ap-southeast-1a",
  "ap-southeast-1b"
]

db_name = "devop-test-tam"

enable_nat_gateway = true

github_owner = "hilarious-tam-1019"

github_repo = "devop-test"

codestar_connection_arn = "arn:aws:codeconnections:ap-southeast-1:707843606560:connection/3d85c631-607c-4971-9444-21ac97aa37dc"
account_id = "707843606560"

services = {
  product = {
    image       = "funnytam1019/product"
    port        = 5001
    target_port = 5001
    environment = {
      APP_NAME = "product-service"
    }
  }

  counter = {
    image       = "funnytam1019/counter"
    port        = 5002
    target_port = 5002
    environment = {
      APP_NAME           = "counter-service"
      IN_DOCKER          = "true"
      PG_URL             = "postgres://postgres:P@ssw0rd@postgres:5432/postgres"
      PG_DSN_URL         = "host=postgres user=postgres password=P@ssw0rd dbname=postgres sslmode=disable"
      RABBITMQ_URL       = "amqp://guest:guest@rabbitmq:5672/"
      PRODUCT_CLIENT_URL = "product:5001"
    }
  }

  barista = {
    image       = "funnytam1019/barista"
    port        = 5003
    target_port = 5003
    environment = {
      APP_NAME     = "barista-service"
      IN_DOCKER    = "true"
      PG_URL       = "postgres://postgres:P@ssw0rd@postgres:5432/postgres"
      PG_DSN_URL   = "host=postgres user=postgres password=P@ssw0rd dbname=postgres sslmode=disable"
      RABBITMQ_URL = "amqp://guest:guest@rabbitmq:5672/"
    }
  }

  kitchen = {
    image       = "funnytam1019/kitchen"
    port        = 5004
    target_port = 5004
    environment = {
      APP_NAME     = "kitchen-service"
      IN_DOCKER    = "true"
      PG_URL       = "postgres://postgres:P@ssw0rd@postgres:5432/postgres"
      PG_DSN_URL   = "host=postgres user=postgres password=P@ssw0rd dbname=postgres sslmode=disable"
      RABBITMQ_URL = "amqp://guest:guest@rabbitmq:5672/"
    }
  }

  proxy = {
    image       = "funnytam1019/proxy"
    port        = 5000
    target_port = 5000
    environment = {
      APP_NAME          = "proxy-service"
      GRPC_PRODUCT_HOST = "product"
      GRPC_PRODUCT_PORT = "5001"
      GRPC_COUNTER_HOST = "counter"
      GRPC_COUNTER_PORT = "5002"
    }
  }

  web = {
    image       = "funnytam1019/web"
    port        = 80
    target_port = 8888
    environment = {
      WEB_PORT          = 8888
      REVERSE_PROXY_URL = "http://54.179.20.146:5000"
    }
  }

  postgres = {
    image       = "postgres:14-alpine"
    port        = 5432
    target_port = 5432
    environment = {
      POSTGRES_DB       = "postgres"
      POSTGRES_USER     = "postgres"
      POSTGRES_PASSWORD = "P@ssw0rd"
    }
  }

  rabbitmq = {
    image       = "rabbitmq:3.11-management-alpine"
    port        = 5672
    target_port = 5672
    environment = {
      RABBITMQ_DEFAULT_USER = "guest"
      RABBITMQ_DEFAULT_PASS = "guest"
    }
  }

 }

