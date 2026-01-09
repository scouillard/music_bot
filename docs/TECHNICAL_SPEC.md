# Discord Music Bot - Technical Specification

## Overview
A minimal Discord music bot in Ruby that streams YouTube audio directly using yt-dlp and ffmpeg.

## System Requirements

### Ruby Version
- Ruby 3.0+ (tested with 3.2.0)

### System Dependencies
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y ffmpeg libsodium-dev libopus-dev yt-dlp

# macOS
brew install ffmpeg libsodium opus yt-dlp

# Verify installations
ffmpeg -version
yt-dlp --version
```

### Ruby Gems
See `Gemfile` for complete list:
- `discordrb` - Discord API wrapper with voice support
- `dotenv` - Environment variable management

## Discord Bot Setup

### 1. Create Discord Application
1. Go to https://discord.com/developers/applications
2. Click "New Application"
3. Name it (e.g., "Music Bot")
4. Navigate to "Bot" section
5. Click "Add Bot"
6. Copy the bot token (save for `.env` file)

### 2. Enable Required Intents
In the Bot settings:
- Enable "SERVER MEMBERS INTENT"
- Enable "MESSAGE CONTENT INTENT"

### 3. Generate Invite URL
1. Go to "OAuth2" > "URL Generator"
2. Select scopes:
   - `bot`
   - `applications.commands`
3. Select bot permissions:
   - Send Messages
   - Connect (voice)
   - Speak (voice)
4. Copy generated URL and open in browser to invite bot to your server

## Architecture

### File Structure
```
music-bot/
├── .env                    # Bot token (git-ignored)
├── .env.example           # Template for environment variables
├── .gitignore            # Git ignore patterns
├── Gemfile               # Ruby dependencies
├── Gemfile.lock          # Locked dependency versions
├── bot.rb                # Main bot application
├── docs/
│   └── TECHNICAL_SPEC.md # This file
└── README.md             # User documentation
```

### Core Components

#### 1. Bot Class (`bot.rb`)
Main entry point orchestrating all functionality.

**Responsibilities:**
- Initialize Discord client with token
- Register command handlers
- Manage bot lifecycle

**Key Methods:**
```ruby
# Initialize bot with token from environment
def initialize(token)

# Start bot and block until terminated
def run
```

#### 2. Play Command Handler
Handles `$play <youtube-url>` command.

**Flow:**
1. Parse command and extract YouTube URL
2. Validate user is in a voice channel
3. Join user's voice channel (if not already connected)
4. Extract audio stream URL using yt-dlp
5. Stream audio to Discord using ffmpeg

**Key Methods:**
```ruby
# Handle $play command
# @param event [Discordrb::Events::MessageEvent] Discord message event
# @param url [String] YouTube URL to play
# @return [void]
def handle_play_command(event, url)

# Extract audio stream URL from YouTube
# @param url [String] YouTube video URL
# @return [String, nil] Direct audio stream URL or nil on failure
def extract_audio_url(url)

# Join voice channel and play audio
# @param event [Discordrb::Events::MessageEvent] Discord message event
# @param stream_url [String] Direct audio stream URL
# @return [void]
def play_audio(event, stream_url)
```

#### 3. Audio Streaming Pipeline
```
YouTube URL
    ↓
yt-dlp (extract stream URL)
    ↓
ffmpeg (transcode to Opus)
    ↓
Discord Voice (UDP packets)
```

**yt-dlp command:**
```bash
yt-dlp -f bestaudio -g --no-playlist <youtube-url>
```
- `-f bestaudio`: Select best audio quality
- `-g`: Print direct URL (no download)
- `--no-playlist`: Single video only

**ffmpeg integration:**
- Input: HTTP stream from yt-dlp
- Output: Opus codec at 48kHz (Discord requirement)
- Handled automatically by discordrb's voice streaming

## API Contract

### Environment Variables
```ruby
# .env
DISCORD_BOT_TOKEN=your_bot_token_here
```

### Bot Interface
```ruby
class MusicBot
  # Initialize with Discord bot token
  # @param token [String] Discord bot token
  def initialize(token)

  # Start the bot (blocking call)
  # @return [void]
  def run
end
```

### Command Handlers
```ruby
# Register in bot initialization
bot.message(start_with: '$play') do |event|
  # event.user - User who sent command
  # event.user.voice_channel - User's current voice channel
  # event.channel - Text channel where command was sent
  # event.content - Full message content
end
```

### Voice Operations
```ruby
# Join voice channel
voice_bot = bot.voice_connect(channel)

# Play audio from URL
voice_bot.play_url(url)

# voice_bot automatically handles:
# - ffmpeg transcoding
# - Opus encoding
# - UDP packet streaming
```

## Error Handling

### User Errors
- User not in voice channel → Reply with helpful message
- Invalid YouTube URL → Reply with error
- Video unavailable → Notify user

### System Errors
- yt-dlp not found → Log error, notify user
- ffmpeg not found → Log error, notify user
- Network errors → Retry once, then fail gracefully

## Future Extensibility

### Planned Commands (not implemented)
Structure allows easy addition of:
- `$stop` - Stop playback and leave channel
- `$skip` - Skip current track
- `$queue` - Show upcoming tracks
- `$pause` / `$resume` - Playback control

### Extension Points
```ruby
# Add new command handler
bot.message(start_with: '$stop') do |event|
  # Implementation here
end

# Queue system (future)
class PlayQueue
  def add(url)
  def next
  def clear
end
```

## Implementation Order

### Phase 1: Setup (files to create)
1. `.gitignore` - Ignore .env, Gemfile.lock, etc.
2. `.env.example` - Template for required environment variables
3. `Gemfile` - Define gem dependencies
4. `.env` - Add actual bot token (user creates from .env.example)

### Phase 2: Core Bot
5. `bot.rb` - Main application:
   - Bot initialization
   - $play command handler
   - yt-dlp integration
   - Voice channel operations

### Phase 3: Documentation
6. `README.md` - Update with complete usage instructions
7. `docs/TECHNICAL_SPEC.md` - This file

### Phase 4: Verification
8. Manual testing checklist:
   - Bot connects to Discord
   - Responds to $play command
   - Joins voice channel
   - Streams audio successfully
   - Handles errors gracefully

## Testing Checklist

### Manual Tests
- [ ] Bot starts without errors
- [ ] Bot appears online in Discord server
- [ ] `$play <valid-youtube-url>` joins voice and plays audio
- [ ] `$play` without URL shows helpful message
- [ ] `$play` when user not in voice shows error
- [ ] Invalid YouTube URL shows error
- [ ] Bot reconnects after network interruption
- [ ] Multiple play commands queue or interrupt (document behavior)

## Security Considerations

### Token Management
- Never commit `.env` to git
- Store token in environment variable only
- Rotate token if accidentally exposed

### Input Validation
- Validate YouTube URL format
- Sanitize URLs before passing to yt-dlp
- Rate limit commands per user (future)

## Performance Notes

### Resource Usage
- Minimal memory footprint (~50MB idle)
- CPU usage during playback: ~5-10% (ffmpeg transcoding)
- Network: Depends on YouTube stream quality

### Optimization Opportunities
- Cache yt-dlp results (URLs expire after ~6 hours)
- Implement connection pooling for voice channels
- Add metrics/monitoring (future)

## Dependencies Rationale

### discordrb
- Mature Discord API wrapper for Ruby
- Built-in voice support with ffmpeg integration
- Active maintenance and good documentation

### yt-dlp
- Modern youtube-dl fork with better reliability
- Regular updates for YouTube changes
- Supports extracting direct stream URLs without downloading

### dotenv
- Simple environment variable management
- Standard in Ruby community
- No runtime overhead

## Configuration

### Bot Prefix
- Current: `$` (e.g., `$play`)
- Configurable in bot.rb if needed

### Voice Settings
- Bitrate: Discord default (64kbps)
- Codec: Opus (required by Discord)
- Sample rate: 48kHz (required by Discord)

## Troubleshooting

### Common Issues

**Bot doesn't respond to commands:**
- Check MESSAGE CONTENT INTENT is enabled
- Verify bot has "Send Messages" permission in channel

**Can't join voice channel:**
- Check bot has "Connect" and "Speak" permissions
- Verify libsodium and opus are installed

**Audio doesn't play:**
- Verify ffmpeg is installed and in PATH
- Check yt-dlp can extract URL: `yt-dlp -g <url>`
- Ensure user is in a voice channel

**yt-dlp errors:**
- Update yt-dlp: `sudo apt-get update && sudo apt-get upgrade yt-dlp`
- Some videos may be geo-restricted or age-restricted

## Monitoring & Logging

### Log Levels
- INFO: Bot started, commands received
- WARN: Recoverable errors (invalid URLs, user errors)
- ERROR: System errors (missing dependencies, network failures)

### Log Format
```
[TIMESTAMP] [LEVEL] Message
```

Example:
```
[2026-01-08 12:00:00] [INFO] Bot started
[2026-01-08 12:01:15] [INFO] User#1234 requested: $play https://youtube.com/...
[2026-01-08 12:01:17] [WARN] User not in voice channel
```

## Deployment Notes

### Local Development
- Run directly: `ruby bot.rb`
- Requires .env file with token
- Ctrl+C to stop

### Production Deployment (Future)
- Use process manager (systemd, Docker)
- Set environment variables via deployment config
- Monitor logs for errors
- Set up restart on failure

## License & Credits
- discordrb: MIT License
- yt-dlp: Unlicense
- This project: (To be determined by user)
