"""
Bit ML Server - AWS Deployment Guide

This script provides instructions for AWS deployment.
Run this file for guided setup information and assistance.
"""

import os
import sys
import webbrowser

def print_header():
    print("="*50)
    print("     BIT ML SERVER - AWS DEPLOYMENT GUIDE     ")
    print("="*50)
    print()

def print_aws_setup_instructions():
    print("1. AWS EC2 INSTANCE SETUP")
    print("-------------------------")
    print("a. Log in to AWS Console: https://aws.amazon.com/console/")
    print("b. Go to EC2 Dashboard and click 'Launch Instance'")
    print("c. Choose Ubuntu Server 20.04 LTS")
    print("d. Select t2.micro (Free tier eligible) or t2.small")
    print("e. Configure Security Group:")
    print("   - Allow SSH (Port 22) from your IP")
    print("   - Allow HTTP (Port 80) from anywhere")
    print("   - Allow HTTPS (Port 443) from anywhere")
    print("   - Allow Custom TCP (Port 5001) from anywhere")
    print("f. Launch instance and download/save your key pair (.pem file)")
    print()
    
    print("2. PREPARE DEPLOYMENT PACKAGE")
    print("----------------------------")
    print("a. Run the aws_setup.sh script to prepare deployment files")
    print("b. This will create a 'deploy' directory with all necessary files")
    print()
    
    print("3. DEPLOY TO AWS")
    print("---------------")
    print("a. Make your .pem key file accessible only to you:")
    print("   chmod 400 /path/to/your-key.pem")
    print()
    print("b. Upload files to your EC2 instance:")
    print("   scp -r -i /path/to/your-key.pem deploy/* ubuntu@YOUR_EC2_PUBLIC_DNS:/home/ubuntu/bit-ml-server/")
    print()
    print("c. SSH into your instance:")
    print("   ssh -i /path/to/your-key.pem ubuntu@YOUR_EC2_PUBLIC_DNS")
    print()
    print("d. Follow the remaining instructions in deploy/README.md")
    print()
    
    print("4. TEST DEPLOYED SERVER")
    print("---------------------")
    print("a. From your local machine, run:")
    print("   curl http://YOUR_EC2_PUBLIC_DNS:5001/health")
    print()
    print("b. You should receive a response like:")
    print('   {"model_available": true, "status": "ok"}')
    print()

def print_domain_setup_instructions():
    print("5. DOMAIN SETUP WITH PORKBUN")
    print("--------------------------")
    print("a. Log in to your Porkbun account")
    print("b. Go to your domain's DNS settings")
    print("c. Add an A record:")
    print("   - Host: 'ml' (or '@' for root domain)")
    print("   - Answer: Your EC2 instance's IP address")
    print("   - TTL: 600 (or default)")
    print()
    print("d. After DNS propagates (up to 24 hours), your server will be accessible at:")
    print("   http://ml.yourdomain.com:5001")
    print()
    
    print("6. CONFIGURE HTTPS (OPTIONAL BUT RECOMMENDED)")
    print("------------------------------------------")
    print("a. Install Certbot on your EC2 instance:")
    print("   sudo snap install --classic certbot")
    print("   sudo ln -s /snap/bin/certbot /usr/bin/certbot")
    print()
    print("b. Set up Nginx as reverse proxy:")
    print("   sudo apt update")
    print("   sudo apt install nginx")
    print()
    print("c. Configure Nginx (sudo nano /etc/nginx/sites-available/bit-ml):")
    print("""
    server {
        listen 80;
        server_name ml.yourdomain.com;
        
        location / {
            proxy_pass http://localhost:5001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    """)
    print()
    print("d. Enable site and get SSL certificate:")
    print("   sudo ln -s /etc/nginx/sites-available/bit-ml /etc/nginx/sites-enabled/")
    print("   sudo certbot --nginx -d ml.yourdomain.com")
    print()
    print("e. Your server will now be accessible via HTTPS:")
    print("   https://ml.yourdomain.com")
    print()

def print_model_update_instructions():
    print("7. UPDATING THE SEED MODEL")
    print("------------------------")
    print("a. Prepare your new model locally using update_seed_model.py")
    print("b. Copy the model to your EC2 instance:")
    print("   scp -i /path/to/your-key.pem output_models/NotificationTimePredictor.pkl ubuntu@YOUR_EC2_PUBLIC_DNS:/home/ubuntu/bit-ml-server/output_models/")
    print()
    print("c. Restart the service to load the new model:")
    print("   sudo systemctl restart bit-ml-server")
    print()

def open_aws_console():
    print("Opening AWS Console in your browser...")
    webbrowser.open("https://console.aws.amazon.com/ec2/")

def open_porkbun_login():
    print("Opening Porkbun login in your browser...")
    webbrowser.open("https://porkbun.com/account/login")

if __name__ == "__main__":
    print_header()
    
    print("This guide will help you deploy the Bit ML Server to AWS")
    print("and connect it to your Porkbun domain.\n")
    
    print_aws_setup_instructions()
    print_domain_setup_instructions()
    print_model_update_instructions()
    
    print("\nWould you like to open any helpful links?")
    print("1. AWS EC2 Console")
    print("2. Porkbun Login")
    print("3. Exit")
    
    choice = input("Enter your choice (1-3): ")
    
    if choice == "1":
        open_aws_console()
    elif choice == "2":
        open_porkbun_login()
    else:
        print("\nGoodbye! Run this script again if you need the deployment guide.")
