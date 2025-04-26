# Step-by-Step AWS Setup Guide

This detailed guide walks you through setting up an AWS EC2 instance for your ML server.

## Step 1: Create an EC2 Instance

1. **Sign in to AWS Console**: https://console.aws.amazon.com/
2. **Navigate to EC2**: Click Services → EC2
3. **Launch an Instance**:
   - Click "Launch Instance"
   - **Name**: ML-Prediction-Server
   - **AMI**: Ubuntu Server 22.04 LTS (64-bit)
   - **Instance Type**: t2.micro (Free Tier eligible)
   - **Key Pair**:
     - Create a new key pair if you don't have one
     - Name it (e.g., "ml-server-key")
     - Download the .pem file and keep it secure
   - **Network Settings**:
     - Create a security group with these rules:
       - SSH: Port 22 from your IP
       - HTTP: Port 80 from anywhere
       - HTTPS: Port 443 from anywhere
       - Custom TCP: Port 5001 from anywhere (for direct API access)
   - **Storage**: 8GB (default) is sufficient
   - Click "Launch Instance"

## Step 2: Connect to Your Instance

1. **Set Key File Permissions** (on Mac/Linux):
   ```bash
   chmod 400 /path/to/your-key.pem
   ```

2. **Connect via SSH**:
   ```bash
   ssh -i /path/to/your-key.pem ubuntu@your-instance-public-ip
   ```

## Step 3: Update Your deploy_to_aws.sh Script

Update these values in the script:
- `AWS_KEY_PATH`: Path to your downloaded .pem file
- `EC2_IP`: Your EC2 instance's public IP address
- `EC2_DOMAIN`: Your desired subdomain (e.g., ml.bitbyte.lol)

## Step 4: Set Up Your Domain

1. **Log in to Porkbun**
2. **Go to bitbyte.lol DNS settings**
3. **Add an A record**:
   - Type: A
   - Host: ml
   - Answer: Your EC2 instance's public IP
   - TTL: 300

## Step 5: Run the Deployment Script

```bash
chmod +x deploy_to_aws.sh
./deploy_to_aws.sh
```

## Step 6: Verify Deployment

1. **Check if services are running**:
   ```bash
   ssh -i /path/to/your-key.pem ubuntu@your-instance-public-ip
   sudo systemctl status ml-server
   sudo systemctl status nginx
   ```

2. **Test your API endpoint**:
   ```bash
   curl -X POST https://ml.bitbyte.lol/predict \
     -H "Content-Type: application/json" \
     -d '{"dayOfWeek": 2, "hourOfDay": 14, "minuteOfHour": 30, "device_activity": 0.7, "device_batteryLevel": 0.8}'
   ```

3. **Visit the web interface** in your browser:
   ```
   https://ml.bitbyte.lol/
   ```

## Common Issues and Troubleshooting

1. **Certificate Issues**: If certbot fails, make sure your domain is correctly pointed to your EC2 IP and DNS has propagated.

2. **Connection Refused**: Check if your security groups allow traffic on ports 80, 443, and 5001.

3. **Service Won't Start**: Check logs with:
   ```bash
   sudo journalctl -u ml-server
   ```

4. **Permission Issues**: Ensure files have correct ownership:
   ```bash
   sudo chown -R ubuntu:ubuntu /home/ubuntu/ml_server
   ```

5. **Nginx Errors**: Check configuration:
   ```bash
   sudo nginx -t
   ```
