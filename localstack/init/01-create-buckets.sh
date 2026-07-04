#!/bin/bash

echo "Creating S3 buckets..."

# Create your buckets (add as many as you need)
awslocal s3 mb s3://my-dev-bucket
awslocal s3 mb s3://my-assets-bucket
awslocal s3 mb s3://my-backups-bucket

echo "Buckets created:"
awslocal s3 ls
