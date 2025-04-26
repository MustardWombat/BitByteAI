# AWS Deployment Guide for ML Prediction Server

This guide walks you through deploying your ML server to AWS.

## 1. AWS Setup Prerequisites

1. **Create an AWS account** if you don't have one: https://aws.amazon.com/
2. **Install the AWS CLI**: https://aws.amazon.com/cli/
3. **Configure AWS credentials**:
   ```
   aws configure
   ```

## 2. Launch an EC2 Instance

1. **Go to EC2 Dashboard**: https://console.aws.amazon.com/ec2/
2. **Click "Launch Instance"**
3. **Choose an AMI**: Select "Ubuntu Server 22.04 LTS"
4. **Choose Instance Type**: t2.micro (Free tier eligible)
5. **Configure Security Groups**:
   - SSH (port 22) - For remote access
   - HTTP (port 80) - For web traffic
   - HTTPS (port 443) - For secure web traffic
   - Custom TCP (port 5001) - For your ML API server
6. **Create or select a key pair** for SSH access
7. **Launch the instance** and note its public IP address

## 3. Configure Your Domain

In Porkbun:
1. Go to your domain (bitbyte.lol)
2. Go to "DNS Records"
3. Add an "A" record:
   - Name: ml
   - Value: [Your EC2 instance IP]
   - TTL: 300

## 4. Deploy Your ML Server

Run the deployment script:
```
./deploy_to_aws.sh
```

## 5. Manual Troubleshooting

If needed, SSH into your EC2 instance:
```
ssh -i your-key.pem ubuntu@your-ec2-ip
```

Common commands:
```
# Check the status of your server
sudo systemctl status ml-server

# View logs
sudo journalctl -u ml-server

# Restart the service
sudo systemctl restart ml-server
```
