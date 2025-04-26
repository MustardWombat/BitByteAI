# AWS Monitoring Guide for ML Server

This guide explains how to monitor and maintain your ML prediction server on AWS.

## Basic Server Monitoring

### Check Service Status

```bash
# SSH into your server
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check if ML server service is running
sudo systemctl status ml-server

# Check if Nginx is running
sudo systemctl status nginx
```

### View Logs

```bash
# Application logs
sudo journalctl -u ml-server
sudo journalctl -u ml-server --since "1 hour ago"

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Setting Up AWS CloudWatch Monitoring

1. **Create an IAM Role** for your EC2 instance:
   - Go to IAM console
   - Create a role with CloudWatchAgentServerPolicy

2. **Attach the Role to Your EC2 Instance**:
   - EC2 dashboard → select your instance
   - Actions → Security → Modify IAM role
   - Select the role you created

3. **Install CloudWatch Agent**:

```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install CloudWatch agent
sudo apt update
sudo apt install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start the agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

4. **Create a CloudWatch Dashboard**:
   - Go to CloudWatch console
   - Create a new dashboard
   - Add widgets for:
     - EC2 metrics (CPU, Memory)
     - Custom metrics from your application

## Setting Up Alerts

1. **Create a CPU Usage Alarm**:
   - CloudWatch console → Alarms → Create alarm
   - Select EC2 → Per-Instance Metrics
   - Find your instance and select CPUUtilization
   - Define threshold (e.g., > 80% for 5 minutes)
   - Configure notification (SNS email)

2. **Create a Status Check Alarm**:
   - Similar process, but select StatusCheckFailed metric

3. **API Error Rate Alarm**:
   - If you've set up custom metrics for API errors
   - Create an alarm based on error rate threshold

## Setting Up AWS Backup

1. **Create regular EC2 snapshots**:
   - EC2 console → Lifecycle Manager
   - Create a snapshot lifecycle policy
   - Schedule daily backups

2. **Back up your model files**:
   - Create a script to upload models to S3:

```bash
#!/bin/bash
# Save to /home/ubuntu/backup-models.sh
AWS_BUCKET="your-backup-bucket-name"
MODEL_DIR="/home/ubuntu/ml_server/output_models"

# Upload models to S3
aws s3 sync $MODEL_DIR s3://$AWS_BUCKET/models/

# Add to crontab to run weekly
# crontab -e
# 0 0 * * 0 /home/ubuntu/backup-models.sh
```

## Auto-Scaling (Advanced)

For production systems with higher traffic:

1. Create an AMI of your configured instance
2. Create a launch template
3. Set up an Auto Scaling Group
4. Configure scaling policies based on CPU usage

Remember to store your models and data in shared storage (like EFS) when using auto-scaling.
