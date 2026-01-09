# Music Bot - Coding Conventions

This document outlines the coding standards and architectural patterns for the Discord Music Bot project.

## Table of Contents

1. [Architecture Principles](#architecture-principles)
2. [Directory Structure](#directory-structure)
3. [Naming Conventions](#naming-conventions)
4. [Code Style](#code-style)
5. [Design Patterns](#design-patterns)
6. [Error Handling](#error-handling)
7. [Testing Guidelines](#testing-guidelines)
8. [Documentation](#documentation)

---

## Architecture Principles

### Single Responsibility Principle (SRP)

Each class should have one clear, well-defined purpose:

- **Commands**: Handle user input and orchestrate services
- **Services**: Encapsulate business logic
- **Models**: Represent data structures

### Dependency Injection

Pass dependencies through constructors rather than creating them internally:

```ruby
# Good
class AudioPlayer
  def initialize(voice_bot)
    @voice_bot = voice_bot
  end
end

# Bad
class AudioPlayer
  def initialize
    @voice_bot = VoiceBot.new  # Hard-coded dependency
  end
end
```

### Separation of Concerns

Keep Discord API logic separate from business logic:

- Discord interactions → `Bot` and `Commands`
- Business logic → `Services`
- Data management → `Models`

---

## Directory Structure

```
music-bot/
├── bin/                          # Executables
│   └── bot
├── lib/
│   ├── music_bot.rb             # Main entry point, requires all files
│   └── music_bot/
│       ├── version.rb           # Version constant
│       ├── bot.rb               # Discord bot client wrapper
│       ├── commands/            # Command handlers
│       │   └── play_command.rb
│       ├── services/            # Business logic
│       │   ├── audio_player.rb
│       │   └── youtube_downloader.rb
│       └── models/              # Data structures
│           └── queue.rb
├── spec/                        # RSpec tests
│   ├── spec_helper.rb
│   └── music_bot/
│       ├── commands/
│       ├── services/
│       └── models/
├── config/                      # Configuration files
│   └── settings.yml
├── docs/                        # Documentation
│   ├── SETUP.md
│   └── conventions.md
└── tmp/                         # Temporary files (gitignored)
```

---

## Naming Conventions

### Files and Directories

- Use `snake_case` for file names: `audio_player.rb`, `play_command.rb`
- Match file names to class names: `AudioPlayer` → `audio_player.rb`
- Use plural for directories containing multiple similar files: `commands/`, `services/`, `models/`

### Classes and Modules

- Use `PascalCase` for class and module names
- Use descriptive, noun-based names for classes
- Suffix service classes with their role: `YoutubeDownloader`, `AudioPlayer`
- Suffix command classes with `Command`: `PlayCommand`

```ruby
module MusicBot
  class Bot
  end

  module Commands
    class PlayCommand
    end
  end

  module Services
    class AudioPlayer
    end
  end
end
```

### Methods and Variables

- Use `snake_case` for methods and variables
- Use verb-based names for methods: `download`, `play`, `validate_url`
- Use question marks for predicate methods: `playing?`, `valid_youtube_url?`
- Use descriptive names over abbreviations: `voice_bot` not `vb`

```ruby
def valid_youtube_url?(url)
  url.match?(%r{^https?://(www\.)?(youtube\.com|youtu\.be)/})
end

def playing?
  @current_track.present?
end
```

### Constants

- Use `SCREAMING_SNAKE_CASE` for constants
- Define module-level constants in appropriate namespace

```ruby
module MusicBot
  VERSION = '1.0.0'

  module Services
    class YoutubeDownloader
      MAX_FILE_SIZE = 100 # MB
      DOWNLOAD_TIMEOUT = 300 # seconds
    end
  end
end
```

---

## Code Style

### Ruby Version

- Minimum Ruby version: 3.0
- Use modern Ruby syntax and features

### Line Length

- Maximum 120 characters per line
- Break long lines logically

### Indentation

- Use 2 spaces for indentation (no tabs)
- Align method parameters when breaking across lines

```ruby
def download_audio(
  url,
  output_path:,
  quality: 'bestaudio',
  timeout: 300
)
  # Implementation
end
```

### String Literals

- Prefer single quotes for strings without interpolation
- Use double quotes for strings with interpolation

```ruby
message = 'Now playing'
formatted = "Now playing: #{title}"
```

### Hash Syntax

- Use symbol keys with new hash syntax when possible

```ruby
# Good
options = { quality: 'bestaudio', timeout: 300 }

# Bad
options = { :quality => 'bestaudio', :timeout => 300 }
```

### Method Definitions

- No space between method name and parameter list
- One space after parameter list before `do` or `{`

```ruby
def play(file_path)
  # Implementation
end

files.each do |file|
  # Implementation
end
```

### Class Definitions

- One empty line between method definitions
- Group related methods together
- Order: public methods, then private methods

```ruby
class AudioPlayer
  def initialize(voice_bot)
    @voice_bot = voice_bot
  end

  def play(file_path)
    validate_file(file_path)
    stream_audio(file_path)
  end

  def stop
    @voice_bot.stop_playing
  end

  private

  def validate_file(file_path)
    raise ArgumentError unless File.exist?(file_path)
  end

  def stream_audio(file_path)
    @voice_bot.play_file(file_path)
  end
end
```

---

## Design Patterns

### Command Pattern

Each bot command is a separate class in `lib/music_bot/commands/`:

```ruby
module MusicBot
  module Commands
    class PlayCommand
      def self.execute(event, url)
        # Validate input
        # Coordinate services
        # Return response
      end
    end
  end
end
```

Commands should:
- Be stateless (use class methods)
- Validate user input
- Orchestrate service calls
- Return user-friendly messages

### Service Objects

Business logic lives in service classes:

```ruby
module MusicBot
  module Services
    class YoutubeDownloader
      def self.download(url, output_dir:)
        # Implementation
      end

      def self.valid_youtube_url?(url)
        # Implementation
      end
    end
  end
end
```

Services should:
- Encapsulate one piece of business logic
- Be independently testable
- Have clear input/output contracts
- Handle their own errors

### Models

Data structures for managing state:

```ruby
module MusicBot
  module Models
    class Queue
      def initialize
        @tracks = []
      end

      def add(track)
        @tracks << track
      end

      def next
        @tracks.shift
      end

      def empty?
        @tracks.empty?
      end
    end
  end
end
```

Models should:
- Represent data structures
- Provide clean interfaces for data manipulation
- Not contain business logic
- Be simple and focused

---

## Error Handling

### Rescue Specific Exceptions

```ruby
# Good
begin
  download_file(url)
rescue Errno::ENOENT => e
  logger.error "File not found: #{e.message}"
rescue StandardError => e
  logger.error "Unexpected error: #{e.message}"
end

# Bad
begin
  download_file(url)
rescue => e
  # Too broad
end
```

### User-Facing Error Messages

Provide helpful messages to Discord users:

```ruby
def execute(event, url)
  unless valid_youtube_url?(url)
    return 'Invalid YouTube URL. Please provide a valid link.'
  end

  # Continue processing
rescue StandardError => e
  'An error occurred while processing your request. Please try again.'
end
```

### Logging

Log errors with context for debugging:

```ruby
def download(url)
  puts "Downloading: #{url}"
  # Implementation
rescue StandardError => e
  puts "Error downloading #{url}: #{e.message}"
  raise
end
```

---

## Testing Guidelines

### Test Structure

- One spec file per class/module
- Mirror the `lib/` directory structure in `spec/`
- Use descriptive test names

```ruby
# spec/music_bot/services/youtube_downloader_spec.rb
RSpec.describe MusicBot::Services::YoutubeDownloader do
  describe '.valid_youtube_url?' do
    it 'returns true for valid YouTube URLs' do
      expect(described_class.valid_youtube_url?('https://youtube.com/watch?v=123')).to be true
    end

    it 'returns false for invalid URLs' do
      expect(described_class.valid_youtube_url?('https://example.com')).to be false
    end
  end
end
```

### Test Coverage

Focus on:
- Happy path: Normal successful execution
- Unhappy path: Error cases and edge cases
- Public API: Don't test private methods directly

### Mocking and Stubbing

Mock external dependencies:

```ruby
RSpec.describe MusicBot::Commands::PlayCommand do
  let(:event) { instance_double(Discordrb::Events::MessageEvent) }
  let(:voice_bot) { instance_double(Discordrb::Voice::VoiceBot) }

  before do
    allow(event).to receive(:user).and_return(double(voice_channel: voice_bot))
  end
end
```

---

## Documentation

### Code Comments

- Use comments sparingly; prefer self-documenting code
- Comment **why**, not **what**
- Document complex algorithms or non-obvious behavior

```ruby
# Good
# yt-dlp requires specific format string to extract audio only
def build_download_command(url)
  "yt-dlp -f bestaudio #{url}"
end

# Bad
# This method downloads a file
def download(url)
  # ...
end
```

### Method Documentation

Use YARD-style documentation for public APIs:

```ruby
# Downloads audio from a YouTube URL
#
# @param url [String] the YouTube video URL
# @param output_dir [String] directory to save the audio file
# @return [String] path to the downloaded file
# @raise [ArgumentError] if URL is invalid
def self.download(url, output_dir:)
  # Implementation
end
```

### README and Guides

- Keep README.md updated with usage instructions
- Maintain SETUP.md for installation and configuration
- Document breaking changes and version updates

---

## Configuration Management

### Environment Variables

- Store secrets in `.env` (never commit)
- Provide `.env.example` with dummy values
- Access via `ENV['VARIABLE_NAME']`

### Settings Files

- Use `config/settings.yml` for non-secret configuration
- Use YAML for structured configuration
- Document all configuration options

---

## Version Control

### Commit Messages

Use clear, descriptive commit messages:

```
Add YouTube URL validation to PlayCommand

- Validates URL format before downloading
- Returns user-friendly error message for invalid URLs
- Adds spec coverage for URL validation
```

### Branch Naming

- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Documentation: `docs/description`

---

## Performance Considerations

### Avoid Blocking Operations

Discord bots should respond quickly:

```ruby
# Good - Acknowledge immediately, process asynchronously
def execute(event, url)
  event.respond 'Downloading...'
  Thread.new { download_and_play(url) }
end

# Bad - Blocks the bot
def execute(event, url)
  download_and_play(url)  # This might take 30+ seconds
  event.respond 'Done!'
end
```

### Clean Up Resources

Remove temporary files after use:

```ruby
def play(url)
  file_path = download(url)
  voice_bot.play_file(file_path)
ensure
  File.delete(file_path) if file_path && File.exist?(file_path)
end
```

---

## Security

### Input Validation

Always validate user input:

```ruby
def execute(event, url)
  return 'Invalid URL' unless valid_youtube_url?(url)

  # Safe to proceed
end
```

### Command Injection Prevention

Never pass user input directly to shell commands:

```ruby
# Bad - Vulnerable to command injection
`yt-dlp #{url}`

# Good - Use proper escaping or libraries
system('yt-dlp', url)
```

### Token Security

- Never hardcode tokens
- Use environment variables
- Regenerate exposed tokens immediately

---

## Summary

Following these conventions ensures:
- **Consistency** across the codebase
- **Maintainability** for future development
- **Readability** for new contributors
- **Quality** through testing and best practices

When in doubt, prioritize simplicity and clarity over cleverness.
