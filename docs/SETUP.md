# Discord Music Bot Setup Guide

This comprehensive guide walks you through creating a Discord bot from scratch and configuring it to play music in voice channels.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Creating a Discord Bot](#creating-a-discord-bot)
3. [Configuring Bot Permissions](#configuring-bot-permissions)
4. [Getting Your Bot Token](#getting-your-bot-token)
5. [Adding Bot to Your Server](#adding-bot-to-your-server)
6. [System Dependencies](#system-dependencies)
7. [Application Setup](#application-setup)
8. [Running the Bot](#running-the-bot)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- A Discord account
- Administrative access to a Discord server (or ability to create one)
- Ruby 3.0 or higher installed
- Basic command line knowledge

---

## Creating a Discord Bot

### Step 1: Access the Discord Developer Portal

1. Navigate to the [Discord Developer Portal](https://discord.com/developers/applications)
2. Log in with your Discord account
3. Click the **"New Application"** button in the top right

### Step 2: Create Your Application

1. Enter a name for your bot (e.g., "Music Bot")
2. Accept the Discord Developer Terms of Service
3. Click **"Create"**

### Step 3: Configure Basic Information

1. You'll be taken to the **General Information** page
2. (Optional) Add an app icon by clicking the icon placeholder
3. (Optional) Add a description
4. Copy your **Application ID** and save it for later

### Step 4: Create the Bot User

1. In the left sidebar, click **"Bot"**
2. Click **"Add Bot"**
3. Click **"Yes, do it!"** to confirm
4. Your bot user is now created!

### Step 5: Configure Bot Settings

On the Bot page, configure these important settings:

#### Public Bot
- **Uncheck** "Public Bot" if you only want to add it to your own servers
- **Check** "Public Bot" if you want others to be able to invite it

#### Requires OAuth2 Code Grant
- Leave this **unchecked** (not needed for this bot)

#### Privileged Gateway Intents
Enable these intents (required for the bot to function):
- ✅ **Presence Intent** (optional)
- ✅ **Server Members Intent** (optional)
- ✅ **Message Content Intent** (REQUIRED - bot needs to read commands)

Click **"Save Changes"** at the bottom.

---

## Configuring Bot Permissions

Your bot needs specific permissions to function properly.

### Required Permissions

In the Bot page, scroll to **Bot Permissions** section. The bot needs:

**Text Permissions:**
- ✅ Send Messages
- ✅ Read Messages/View Channels
- ✅ Read Message History
- ✅ Add Reactions (optional, for UI feedback)

**Voice Permissions:**
- ✅ Connect
- ✅ Speak
- ✅ Use Voice Activity

The permissions integer for these is: `36703232`

---

## Getting Your Bot Token

### Step 1: Reveal Your Token

1. On the **Bot** page, find the **TOKEN** section
2. Click **"Reset Token"** (if this is your first time, it may say "Copy")
3. Click **"Yes, do it!"** to confirm
4. Your token will be displayed

### Step 2: Copy and Secure Your Token

1. Click **"Copy"** to copy the token to your clipboard
2. **IMMEDIATELY** save this token somewhere secure
3. **NEVER** share this token publicly or commit it to version control

⚠️ **WARNING**: Your bot token is like a password. Anyone with this token can control your bot. If it's ever exposed:
1. Go back to the Developer Portal
2. Click **"Reset Token"**
3. Update your `.env` file with the new token

---

## Adding Bot to Your Server

### Step 1: Generate OAuth2 URL

1. In the left sidebar, click **"OAuth2"** → **"URL Generator"**
2. In the **SCOPES** section, check:
   - ✅ `bot`
   - ✅ `applications.commands` (for slash commands - future feature)

3. In the **BOT PERMISSIONS** section, check the same permissions listed above:
   - Send Messages
   - Read Messages/View Channels
   - Read Message History
   - Connect
   - Speak
   - Use Voice Activity

4. Scroll to the bottom and copy the **Generated URL**

### Step 2: Invite Bot to Server

1. Paste the URL into your browser
2. Select the server you want to add the bot to
3. Click **"Continue"**
4. Review the permissions and click **"Authorize"**
5. Complete the CAPTCHA if prompted

Your bot is now added to your server! It will appear offline until you run the application.

---

## System Dependencies

The bot requires several system-level dependencies to function.

### 1. Install yt-dlp

`yt-dlp` is required to download audio from YouTube.

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install yt-dlp
```

**macOS:**
```bash
brew install yt-dlp
```

**Alternative (pip):**
```bash
pip install yt-dlp
```

Verify installation:
```bash
yt-dlp --version
```

### 2. Install FFmpeg

FFmpeg is required for audio processing and streaming.

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ffmpeg
```

**macOS:**
```bash
brew install ffmpeg
```

Verify installation:
```bash
ffmpeg -version
```

### 3. Install libsodium

libsodium is required for voice channel encryption.

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install libsodium-dev
```

**macOS:**
```bash
brew install libsodium
```

### 4. Install libopus

Opus codec for voice encoding.

**Ubuntu/Debian:**
```bash
sudo apt install libopus-dev
```

**macOS:**
```bash
brew install opus
```

---

## Application Setup

### Step 1: Install Ruby Dependencies

```bash
bundle install
```

### Step 2: Configure Environment Variables

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` and add your bot token:
```bash
DISCORD_BOT_TOKEN=your_actual_bot_token_here
COMMAND_PREFIX=$
DOWNLOAD_DIR=./tmp
```

Replace `your_actual_bot_token_here` with the token you copied earlier.

### Step 3: Create Temporary Directory

```bash
mkdir -p tmp
```

This directory will store downloaded audio files temporarily.

---

## Running the Bot

### Start the Bot

```bash
./bin/bot
```

or

```bash
ruby bin/bot
```

You should see output like:
```
Music Bot v1.0.0 starting...
Bot is ready! Logged in as: YourBotName#1234
```

The bot will now appear **online** in your Discord server!

---

## Using the Bot

### Basic Commands

**Play a song:**
```
$play https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

### Requirements for Playing Music

1. You must be in a voice channel
2. The bot must have permission to join that voice channel
3. The URL must be a valid YouTube URL

### Command Flow

1. User joins a voice channel
2. User types `$play <youtube_url>` in a text channel
3. Bot joins the user's voice channel
4. Bot downloads the audio
5. Bot plays the audio in the voice channel

---

## Troubleshooting

### Bot appears offline

**Problem:** Bot doesn't come online after running `./bin/bot`

**Solutions:**
- Check that your token is correct in `.env`
- Ensure you've enabled **Message Content Intent** in the Developer Portal
- Check for error messages in the console

### "Invalid token" error

**Problem:** Bot crashes with authentication error

**Solutions:**
- Verify your token is correctly copied (no extra spaces)
- Reset your token in the Developer Portal and update `.env`
- Ensure you're using the **Bot Token**, not the Client Secret

### Bot doesn't respond to commands

**Problem:** Bot is online but doesn't react to `$play`

**Solutions:**
- Verify **Message Content Intent** is enabled
- Check that the command prefix matches (default is `$`)
- Ensure bot has "Read Messages" permission in the channel
- Check bot's role position (must be above any roles that restrict permissions)

### "yt-dlp not found" error

**Problem:** Bot can't download audio

**Solutions:**
- Verify yt-dlp is installed: `yt-dlp --version`
- Ensure yt-dlp is in your system PATH
- Try reinstalling yt-dlp

### "FFmpeg not found" error

**Problem:** Bot can't process audio

**Solutions:**
- Verify FFmpeg is installed: `ffmpeg -version`
- Ensure FFmpeg is in your system PATH
- Install FFmpeg using your system package manager

### Bot joins voice channel but no audio plays

**Problem:** Bot connects but stays silent

**Solutions:**
- Check that libsodium is installed
- Verify libopus is installed
- Check that audio file was downloaded (look in `tmp/` directory)
- Ensure you're not deafened in Discord
- Check Discord voice settings (output device, volume)

### Permission errors

**Problem:** Bot can't join voice channel

**Solutions:**
- Verify bot has "Connect" and "Speak" permissions
- Check channel-specific permission overrides
- Ensure bot's role has necessary permissions
- Try moving bot's role higher in the role hierarchy

### Download failures

**Problem:** Bot fails to download from YouTube

**Solutions:**
- Update yt-dlp: `pip install -U yt-dlp` or `brew upgrade yt-dlp`
- Check that the YouTube URL is valid
- Verify you have internet connectivity
- Check `tmp/` directory has write permissions
- Some videos may be region-locked or age-restricted

---

## Advanced Configuration

### Changing Command Prefix

Edit `.env`:
```bash
COMMAND_PREFIX=!
```

Now commands use `!play` instead of `$play`

### Adjusting Settings

Edit `config/settings.yml` to modify:
- Maximum download size
- Audio quality preferences
- Timeout values
- Custom response messages

---

## Security Best Practices

1. **Never commit `.env` to version control** (already in `.gitignore`)
2. **Use environment variables for secrets** (tokens, API keys)
3. **Regenerate your token if it's ever exposed**
4. **Set appropriate bot permissions** (principle of least privilege)
5. **Keep dependencies updated** for security patches

---

## Next Steps

Once your bot is running successfully:

1. Test the `$play` command with various YouTube URLs
2. Explore the codebase to understand how it works
3. Consider implementing additional features:
   - Queue system for multiple songs
   - Skip/stop commands
   - Volume control
   - Playlist support

---

## Additional Resources

- [Discord Developer Documentation](https://discord.com/developers/docs/intro)
- [discordrb Documentation](https://github.com/shardlab/discordrb)
- [yt-dlp Documentation](https://github.com/yt-dlp/yt-dlp)
- [Discord Developer Community](https://discord.gg/discord-developers)

---

## Support

If you encounter issues not covered in this guide:

1. Check the application logs for error messages
2. Review the troubleshooting section
3. Ensure all system dependencies are installed
4. Verify your Discord bot configuration
5. Open an issue on the project repository with details about your problem

Happy music listening! 🎵
