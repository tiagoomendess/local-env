# Local Env

Portable local environment for common development dependencies — databases, caching, and AWS service emulation. Spin up the whole stack with a single command.

## Services

| Service            | Image                     | Default Port | Description                  |
|--------------------|---------------------------|--------------|------------------------------|
| MySQL              | `mysql:8.0`               | `3306`       | Relational database          |
| Redis              | `redis:7-alpine`          | `6379`       | Cache / message broker       |
| MongoDB            | `mongo:7`                 | `27017`      | Document database            |
| LocalStack S3      | `localstack/localstack:3` | `4566`       | AWS S3 emulation             |
| LocalStack SQS     | `localstack/localstack:3` | `4566`       | AWS SQS queues               |
| LocalStack SNS     | `localstack/localstack:3` | `4566`       | AWS SNS topics & subscriptions |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose plugin)
- `make`

## Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd local-env

# 2. Create your .env from the example
cp .env.example .env

# 3. Edit .env with your preferred passwords / settings
#    (the defaults work fine for local dev)

# 4. Start everything
make start
```

## Common Commands

```bash
make start              # Start all services
make stop               # Stop all services
make restart            # Restart all services
make status             # Show container status
make health             # Show health of all containers
make logs               # Tail logs for all services

# Per-service control
make start-mysql        # Start only MySQL
make start-redis        # Start only Redis
make start-mongodb      # Start only MongoDB
make start-localstack   # Start only LocalStack

make stop-mysql / stop-redis / stop-mongodb / stop-localstack
make restart-mysql / restart-redis / restart-mongodb / restart-localstack
make mysql-logs / redis-logs / mongodb-logs / localstack-logs

# Shells
make mysql-shell        # MySQL CLI (root)
make mysql-shell-dev    # MySQL CLI (dev user)
make redis-shell        # Redis CLI
make mongodb-shell      # MongoDB shell (root)
make mongodb-shell-dev  # MongoDB shell (dev user)
make s3-shell           # Bash in LocalStack container

# S3 / SQS / SNS
make s3-ls              # List all S3 buckets
make sqs-ls             # List all SQS queues
make sns-ls             # List all SNS topics

# Data management
make clean              # Remove containers, keep data volumes
make clean-all          # Remove containers AND data (irreversible)
make backup-mysql       # Dump MySQL database to backups/
make rebuild            # Rebuild and restart all services
```

## S3 Usage

LocalStack emulates AWS S3 on `http://localhost:4566`. Use the AWS CLI with `--endpoint-url`:

```bash
# List buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Upload a file
aws --endpoint-url=http://localhost:4566 s3 cp file.txt s3://my-dev-bucket/

# List objects in a bucket
aws --endpoint-url=http://localhost:4566 s3 ls s3://my-dev-bucket/
```

Inside the LocalStack container, use `awslocal` (no endpoint flag needed):

```bash
make s3-shell
awslocal s3 ls
awslocal s3 mb s3://my-new-bucket
```

### Default buckets

The init script (`localstack/init/01-create-buckets.sh`) creates these buckets on first start:

- `my-dev-bucket`
- `my-assets-bucket`
- `my-backups-bucket`

Edit the script to add or remove buckets for your projects.

### S3 credentials

LocalStack accepts any non-empty credentials. The `.env.example` defaults work:

```
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

For use in application code, configure your AWS SDK to point at `http://localhost:4566`.

## SQS Usage

```bash
# List queues
aws --endpoint-url=http://localhost:4566 sqs list-queues

# Send a message
aws --endpoint-url=http://localhost:4566 sqs send-message \
  --queue-url http://localhost:4566/000000000000/my-dev-queue \
  --message-body "hello world"

# Receive messages
aws --endpoint-url=http://localhost:4566 sqs receive-message \
  --queue-url http://localhost:4566/000000000000/my-dev-queue
```

### Default queues

The init script (`localstack/init/02-create-queues-topics.sh`) creates on first start:

- `my-dev-queue` — standard queue, also subscribed to `my-dev-topic`
- `my-jobs-queue` — standard queue
- `my-ordered-queue.fifo` — FIFO queue with content-based deduplication

## SNS Usage

```bash
# List topics
aws --endpoint-url=http://localhost:4566 sns list-topics

# Publish a message to a topic (fan-out to all subscribers)
aws --endpoint-url=http://localhost:4566 sns publish \
  --topic-arn arn:aws:sns:us-east-1:000000000000:my-dev-topic \
  --message "hello subscribers"

# List subscriptions for a topic
aws --endpoint-url=http://localhost:4566 sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:000000000000:my-dev-topic
```

### Default topics

- `my-dev-topic` — subscribed to `my-dev-queue` (SNS→SQS fan-out wired up)
- `my-events-topic` — unsubscribed by default; add your own subscriptions

Edit `localstack/init/02-create-queues-topics.sh` to add or remove queues, topics, and subscriptions.

## Data persistence

| Service   | Volume path           | Notes                                          |
|-----------|-----------------------|------------------------------------------------|
| MySQL     | `./mysql/data`        | Persisted across restarts                      |
| Redis     | `./redis/data`        | AOF persistence enabled                        |
| MongoDB   | `./mongodb/data`      | Persisted across restarts                      |
| LocalStack | `./localstack/data`  | `PERSISTENCE=1`; state survives restarts       |

Data folders are git-ignored (`.gitignore` covers `*/data/*`). Only the `.gitkeep` placeholder is tracked.
