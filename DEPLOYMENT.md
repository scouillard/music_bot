# Deployment Guide for Hetzner VM

## Prerequisites on Hetzner VM

Install Docker and Docker Compose:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose (if not included)
sudo apt install docker-compose-plugin -y

# Log out and back in for group changes to take effect
```

## Deployment Steps

### 1. Transfer Files to VM

From your local machine:

```bash
# Option A: Using git (recommended)
ssh your-vm-ip
git clone https://github.com/yourusername/music_bot.git /opt/music_bot
cd /opt/music_bot

# Option B: Using rsync
rsync -avz --exclude '.git' --exclude 'node_modules' \
  /home/gh0st/projects/music_bot/ user@your-vm-ip:/opt/music_bot/

# Option C: Using scp
cd /home/gh0st/projects/music_bot
tar czf music_bot.tar.gz --exclude='.git' --exclude='node_modules' .
scp music_bot.tar.gz user@your-vm-ip:/tmp/
ssh user@your-vm-ip
sudo mkdir -p /opt/music_bot
sudo tar xzf /tmp/music_bot.tar.gz -C /opt/music_bot
```

### 2. Configure Environment Variables

On the VM:

```bash
cd /opt/music_bot
cp .env.example .env
nano .env  # or vim .env
```

Add your Discord bot token:
```
DISCORD_BOT_TOKEN=your_actual_bot_token_here
```

### 3. Build and Test

```bash
# Build the Docker image
sudo docker compose build

# Test run (Ctrl+C to stop)
sudo docker compose up

# If everything works, stop it
sudo docker compose down
```

### 4. Set Up Systemd Service

```bash
# Copy service file
sudo cp discord-music-bot.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable discord-music-bot.service

# Start the service
sudo systemctl start discord-music-bot.service

# Check status
sudo systemctl status discord-music-bot.service
```

## Managing the Bot

### Start/Stop/Restart

```bash
# Start
sudo systemctl start discord-music-bot

# Stop
sudo systemctl stop discord-music-bot

# Restart
sudo systemctl restart discord-music-bot

# Status
sudo systemctl status discord-music-bot
```

### View Logs

```bash
# Systemd logs
sudo journalctl -u discord-music-bot -f

# Docker logs
sudo docker logs -f discord-music-bot

# Last 100 lines
sudo docker logs --tail 100 discord-music-bot
```

### Update the Bot

```bash
# If using git
cd /opt/music_bot
git pull

# Rebuild and restart
sudo systemctl restart discord-music-bot

# Or reload (pulls and restarts)
sudo systemctl reload discord-music-bot
```

### Manually Managing with Docker Compose

```bash
cd /opt/music_bot

# Start
sudo docker compose up -d

# Stop
sudo docker compose down

# View logs
sudo docker compose logs -f

# Rebuild after code changes
sudo docker compose build
sudo docker compose up -d
```

## Troubleshooting

### Check if Docker is running
```bash
sudo systemctl status docker
```

### Rebuild image
```bash
cd /opt/music_bot
sudo docker compose build --no-cache
sudo docker compose up -d
```

### Check container status
```bash
sudo docker ps -a
```

### Access container shell
```bash
sudo docker exec -it discord-music-bot bash
```

### Remove and recreate
```bash
sudo docker compose down
sudo docker compose up -d
```

## Security Notes

- The `.env` file contains sensitive tokens - ensure it's not committed to git
- The service runs as a non-root user inside the container
- Consider setting up a firewall (ufw) on your VM
- Keep your system and Docker updated regularly

## Auto-Start on Boot

The systemd service is configured to start automatically on boot. To verify:

```bash
sudo systemctl is-enabled discord-music-bot
```

Should return: `enabled`
