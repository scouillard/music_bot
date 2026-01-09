# Discord Music Bot

A minimal Discord music bot in Ruby that streams YouTube audio directly to voice channels using yt-dlp and ffmpeg.

## Features

- Stream YouTube audio directly to Discord voice channels
- Simple `$play <youtube-url>` command
- No downloading - streams audio in real-time
- Minimal dependencies and clean code structure
- Easy to extend with additional commands

## Prerequisites

### System Dependencies

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y ffmpeg libsodium-dev libopus-dev yt-dlp
```

#### macOS
```bash
brew install ffmpeg libsodium opus yt-dlp
```

#### Verify Installation
```bash
ffmpeg -version
yt-dlp --version
```

### Ruby Version
- Ruby 3.0 or higher required

## Discord Bot Setup

### 1. Create Discord Application

1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Give it a name (e.g., "Music Bot")
4. Navigate to the "Bot" section in the left sidebar
5. Click "Add Bot"
6. Copy the bot token (you'll need this for the `.env` file)

### 2. Enable Required Intents

In the Bot settings page:
- Scroll down to "Privileged Gateway Intents"
- Enable **SERVER MEMBERS INTENT**
- Enable **MESSAGE CONTENT INTENT**

### 3. Invite Bot to Your Server

1. Go to "OAuth2" > "URL Generator"
2. Select scopes:
   - `bot`
   - `applications.commands`
3. Select bot permissions:
   - Send Messages
   - Connect (voice)
   - Speak (voice)
4. Copy the generated URL
5. Open the URL in your browser to invite the bot to your server

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd music-bot
```

### 2. Install Ruby Dependencies

```bash
bundle install
```

### 3. Configure Environment

Create a `.env` file from the template:
```bash
cp .env.example .env
```

Edit `.env` and add your Discord bot token:
```
DISCORD_BOT_TOKEN=your_actual_bot_token_here
```

**Important:** Never commit your `.env` file or share your bot token publicly!

## Usage

### Start the Bot

```bash
ruby bot.rb
```

You should see:
```
Starting Discord Music Bot...
Bot logged in as: YourBotName
Ready to play music!
```

### Commands

#### Play a YouTube Video

Join a voice channel in your Discord server, then type in any text channel:

```
$play https://youtube.com/watch?v=dQw4w9WgXcQ
```

The bot will:
1. Join your voice channel
2. Extract the audio stream from YouTube
3. Start playing the audio

#### Supported URL Formats

- `https://youtube.com/watch?v=VIDEO_ID`
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`

## Development

### Run Tests

```bash
bundle exec rspec
```

### Run Linter

```bash
bin/rubocop
```

## Project Structure

```
music-bot/
├── .env                         # Bot token (git-ignored)
├── .env.example                # Environment variable template
├── .gitignore                  # Git ignore patterns
├── Gemfile                     # Ruby dependencies
├── Gemfile.lock                # Locked dependency versions
├── bot.rb                      # Main bot executable (entry point)
├── lib/                        # Library code
│   ├── music_bot.rb           # Main MusicBot class
│   └── music_bot/             # Component classes
│       ├── config.rb          # Configuration constants
│       ├── commands.rb        # All command classes
│       ├── queue_manager.rb   # Queue management
│       ├── youtube_service.rb # YouTube/yt-dlp operations
│       ├── audio_player.rb    # Voice connection & playback
│       └── content_filter.rb  # Content policy checking
├── spec/                       # RSpec tests
│   ├── spec_helper.rb         # RSpec configuration
│   └── bot_spec.rb            # Bot tests
├── docs/
│   └── TECHNICAL_SPEC.md      # Technical specification
└── README.md                   # This file
```

## How It Works

### Architecture

```
User Command ($play <url>)
    ↓
Extract YouTube URL
    ↓
Validate user is in voice channel
    ↓
yt-dlp extracts audio stream URL
    ↓
ffmpeg transcodes to Opus format
    ↓
Stream to Discord voice channel
```

### Technologies

- **discordrb** - Ruby Discord API wrapper with voice support
- **yt-dlp** - YouTube audio extraction (youtube-dl fork)
- **ffmpeg** - Audio transcoding to Opus codec
- **dotenv** - Environment variable management

## Troubleshooting

### Bot doesn't respond to commands

- Verify **MESSAGE CONTENT INTENT** is enabled in Discord Developer Portal
- Check that the bot has "Send Messages" permission in the channel

### Can't join voice channel

- Verify **Connect** and **Speak** permissions are granted
- Ensure libsodium and opus are installed: `dpkg -l | grep libsodium`

### Audio doesn't play

- Verify ffmpeg is installed: `ffmpeg -version`
- Test yt-dlp manually: `yt-dlp -g <youtube-url>`
- Ensure you're in a voice channel when using the command

### yt-dlp errors

- Update yt-dlp: `sudo apt-get update && sudo apt-get upgrade yt-dlp` (Linux) or `brew upgrade yt-dlp` (macOS)
- Some videos may be geo-restricted or age-restricted

## Future Enhancements

The code is structured to easily add:

- `$stop` - Stop playback and leave channel
- `$skip` - Skip to next track
- `$queue` - Display upcoming tracks
- `$pause` / `$resume` - Playback control
- `$volume` - Adjust volume

See `docs/TECHNICAL_SPEC.md` for extension points.

## Security Notes

- Never commit `.env` file to version control
- Rotate your bot token if accidentally exposed
- The `.gitignore` file already excludes `.env`

## License

MIT License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `bundle exec rspec`
5. Run linter: `bin/rubocop`
6. Submit a pull request
