# Production Server Setup Guide

This guide explains how to set up your ML prediction server on bitbyte.lol.

## Prerequisites

1. SSH access to your bitbyte.lol server
2. Nginx installed on your server
3. Python 3.8+ installed on your server
4. Supervisor installed (`sudo apt install supervisor`)
5. Certbot installed for SSL certificates

## Manual Setup Steps

If the automatic deployment script fails, follow these steps:

1. **Create directory structure on server**
```bash
mkdir -p /var/www/bitbyte.lol/ml_server
```

2. **Upload code**
```bash
# From your local machine:
rsync -avz --exclude 'venv' --exclude '__pycache__' --exclude '*.pyc' --exclude '.git' ./Server/ username@bitbyte.lol:/var/www/bitbyte.lol/ml_server/
```

3. **Set up Python environment**
```bash
cd /var/www/bitbyte.lol/ml_server
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements-prod.txt
```

4. **Test the setup**
```bash
./run_complete_test.sh
```

5. **Create Supervisor config**
```bash
sudo nano /etc/supervisor/conf.d/ml_prediction.conf
# Add the configuration as shown in the deployment script
sudo supervisorctl reread
sudo supervisorctl update
```

6. **Configure Nginx**
```bash
sudo nano /etc/nginx/sites-available/ml.bitbyte.lol
# Add the Nginx configuration as shown in the deployment script
sudo ln -sf /etc/nginx/sites-available/ml.bitbyte.lol /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

7. **Set up SSL certificate**
```bash
sudo certbot --nginx -d ml.bitbyte.lol
```

## Monitoring and Maintenance

- **View logs:**
  ```bash
  sudo tail -f /var/log/ml_prediction.err.log
  sudo tail -f /var/log/ml_prediction.out.log
  ```

- **Restart the service:**
  ```bash
  sudo supervisorctl restart ml_prediction
  ```

- **Update deployed code:**
  ```bash
  cd /var/www/bitbyte.lol/ml_server
  git pull  # If you set up git
  # or rsync again from your local machine
  source venv/bin/activate
  pip install -r requirements-prod.txt  # If dependencies changed
  sudo supervisorctl restart ml_prediction
  ```

## Security Considerations

1. Set up a firewall to restrict access
2. Use a non-root user for running the service
3. Implement rate limiting in Nginx
4. Add authentication to your API endpoints
