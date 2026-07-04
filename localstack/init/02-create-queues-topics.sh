#!/bin/bash

echo "Creating SQS queues..."

# Standard queues
awslocal sqs create-queue --queue-name my-dev-queue
awslocal sqs create-queue --queue-name my-jobs-queue

# FIFO queue (name must end in .fifo)
awslocal sqs create-queue --queue-name my-ordered-queue.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true

echo "Creating SNS topics..."

awslocal sns create-topic --name my-dev-topic
awslocal sns create-topic --name my-events-topic

echo "Subscribing SQS queues to SNS topics (fan-out)..."

# Resolve ARNs
REGION=$(awslocal configure get region 2>/dev/null || echo "us-east-1")
ACCOUNT_ID="000000000000"

DEV_TOPIC_ARN="arn:aws:sns:${REGION}:${ACCOUNT_ID}:my-dev-topic"
DEV_QUEUE_URL=$(awslocal sqs get-queue-url --queue-name my-dev-queue --query QueueUrl --output text)
DEV_QUEUE_ARN="arn:aws:sqs:${REGION}:${ACCOUNT_ID}:my-dev-queue"

# Subscribe the dev queue to the dev topic
awslocal sns subscribe \
  --topic-arn "$DEV_TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$DEV_QUEUE_ARN"

echo "Queues:"
awslocal sqs list-queues

echo "Topics:"
awslocal sns list-topics
