# Discord Music Bot

A Ruby-based Discord bot that plays audio from YouTube URLs in voice channels using the discordrb gem.

## Features

- Play audio from YouTube URLs in Discord voice channels
- Simple command interface with `$play` command
- Automatic voice channel joining
- Clean audio extraction with yt-dlp
- Extensible architecture for future features (queue, skip, stop, etc.)

## Prerequisites

- Ruby 3.0 or higher
- Discord Bot Token (see [Setup Guide](docs/SETUP.md))
- System dependencies:
  - `yt-dlp` - YouTube audio downloader
  - `ffmpeg` - Audio processing
  - `libsodium` - Voice encryption
  - `libopus` - Audio codec

## Quick Start

### 1. Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install yt-dlp ffmpeg libsodium-dev libopus-dev
```

**macOS:**
```bash
brew install yt-dlp ffmpeg libsodium opus
```

### 2. Install Ruby Dependencies

```bash
bundle install
```

### 3. Configure Environment

Copy the example environment file and add your Discord bot token:

```bash
cp .env.example .env
```

Edit `.env` and set your bot token:
```
DISCORD_BOT_TOKEN=your_bot_token_here
COMMAND_PREFIX=$
DOWNLOAD_DIR=./tmp
```

### 4. Run the Bot

```bash
./bin/bot
```

The bot will start and appear online in your Discord server.

## Usage

### Play Command

Join a voice channel in Discord, then use the play command in any text channel:

```
$play https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

The bot will:
1. Join your voice channel
2. Download the audio from YouTube
3. Play the audio in the voice channel

## Discord Bot Setup

For a comprehensive guide on creating a Discord bot from scratch, obtaining a bot token, and configuring permissions, see [docs/SETUP.md](docs/SETUP.md).

This guide covers:
- Creating a Discord application and bot
- Configuring bot permissions and intents
- Getting your bot token
- Inviting the bot to your server
- Installing system dependencies
- Troubleshooting common issues

## Project Structure

```
music-bot/
├── bin/
│   └── bot                          # Executable to start the bot
├── lib/
│   ├── music_bot.rb                # Main entry point
│   └── music_bot/
│       ├── version.rb              # Version constant
│       ├── bot.rb                  # Discord bot client
│       ├── commands/
│       │   └── play_command.rb     # $play command handler
│       ├── services/
│       │   ├── audio_player.rb     # Audio playback service
│       │   └── youtube_downloader.rb # YouTube download service
│       └── models/
│           └── queue.rb            # Queue data structure (future)
├── config/
│   └── settings.yml                # Bot configuration
├── docs/
│   ├── SETUP.md                    # Comprehensive setup guide
│   └── conventions.md              # Coding standards
└── spec/                           # RSpec tests
```

## Configuration

### Environment Variables (.env)

- `DISCORD_BOT_TOKEN` - Your Discord bot token (required)
- `COMMAND_PREFIX` - Command prefix (default: `$`)
- `DOWNLOAD_DIR` - Directory for temporary audio files (default: `./tmp`)

### Settings (config/settings.yml)

Customize bot behavior by editing `config/settings.yml`:

- `max_download_size` - Maximum audio file size in MB
- `audio_quality` - Audio quality preference
- `download_timeout` - Timeout for downloads
- `max_queue_size` - Maximum queue size
- Custom response messages

## Development

### Running Tests

```bash
bundle exec rspec
```

### Code Style

```bash
bundle exec rubocop
```

### Coding Conventions

See [docs/conventions.md](docs/conventions.md) for detailed coding standards and architectural patterns.

## Future Features

The architecture is designed to support future enhancements:

- **Queue System**: Add multiple tracks to a playlist
- **Playback Controls**: Skip, stop, pause, resume
- **Volume Control**: Adjust audio volume
- **Playlist Support**: YouTube playlists
- **Search**: Search YouTube by keywords
- **Now Playing**: Display current track info

## Troubleshooting

### Bot doesn't come online
- Verify your bot token is correct in `.env`
- Ensure Message Content Intent is enabled in Discord Developer Portal

### Bot doesn't respond to commands
- Check that bot has "Read Messages" permission
- Verify command prefix matches (default: `$`)
- Enable Message Content Intent in Developer Portal

### Audio doesn't play
- Ensure all system dependencies are installed (yt-dlp, ffmpeg, libsodium, libopus)
- Check that bot has "Connect" and "Speak" permissions
- Verify you're in a voice channel

### Download failures
- Update yt-dlp: `pip install -U yt-dlp`
- Check internet connectivity
- Verify YouTube URL is valid

See [docs/SETUP.md](docs/SETUP.md) for more troubleshooting tips.

## Security

- Never commit your `.env` file
- Keep your bot token secret
- Regenerate token if exposed
- Use environment variables for all secrets

## Contributing

1. Follow coding conventions in [docs/conventions.md](docs/conventions.md)
2. Write tests for new features
3. Ensure tests pass: `bundle exec rspec`
4. Ensure code style passes: `bundle exec rubocop`

## License

MIT License

## Support

For detailed setup instructions and troubleshooting, see [docs/SETUP.md](docs/SETUP.md).

For project coding standards and architecture, see [docs/conventions.md](docs/conventions.md).
