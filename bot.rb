#!/usr/bin/env ruby
# frozen_string_literal: true

require 'discordrb'
require 'dotenv/load'
require 'open3'
require 'logger'

# Discord Music Bot
# Streams YouTube audio to Discord voice channels using yt-dlp and ffmpeg
class MusicBot
  COMMAND_PREFIX = '$'
  YOUTUBE_URL_PATTERN = %r{^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+}

  attr_reader :bot, :logger

  # Initialize the music bot
  # @param token [String] Discord bot token
  def initialize(token:)
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO

    @bot = Discordrb::Bot.new(token: token)
    register_commands
    register_event_handlers
  end

  # Start the bot (blocking)
  def run
    logger.info 'Starting Discord Music Bot...'
    bot.run
  end

  private

  # Register command handlers
  def register_commands
    bot.message(start_with: "#{COMMAND_PREFIX}play") do |event|
      handle_play_command(event)
    end
  end

  # Register event handlers
  def register_event_handlers
    bot.ready do
      logger.info "Bot logged in as: #{bot.profile.username}"
      logger.info 'Ready to play music!'
    end
  end

  # Handle the $play command
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  def handle_play_command(event)
    logger.info "User #{event.user.username} requested: #{event.content}"

    # Extract URL from command
    url = extract_url_from_message(event.content)
    unless url
      event.respond 'Usage: `$play <youtube-url>`'
      return
    end

    # Validate YouTube URL
    unless valid_youtube_url?(url)
      event.respond 'Invalid YouTube URL. Please provide a valid YouTube video link.'
      return
    end

    # Check if user is in a voice channel
    voice_channel = event.user.voice_channel
    unless voice_channel
      event.respond 'You must be in a voice channel to use this command!'
      return
    end

    # Extract audio stream URL
    event.respond 'Fetching audio stream...'
    stream_url = extract_audio_url(url)
    unless stream_url
      event.respond 'Failed to extract audio from YouTube. The video may be unavailable or restricted.'
      return
    end

    # Play the audio
    event.respond 'Playing now! 🎵'
    play_audio(event, voice_channel, stream_url)
  rescue StandardError => e
    logger.error "Error in handle_play_command: #{e.message}"
    logger.error e.backtrace.join("\n")
    event.respond 'An error occurred while trying to play the audio. Please try again.'
  end

  # Extract URL from message content
  # @param message [String] Full message content
  # @return [String, nil] Extracted URL or nil
  def extract_url_from_message(message)
    parts = message.split
    return nil if parts.length < 2

    parts[1]
  end

  # Validate YouTube URL format
  # @param url [String] URL to validate
  # @return [Boolean] True if valid YouTube URL
  def valid_youtube_url?(url)
    url.match?(YOUTUBE_URL_PATTERN)
  end

  # Extract direct audio stream URL from YouTube using yt-dlp
  # @param url [String] YouTube video URL
  # @return [String, nil] Direct audio stream URL or nil on failure
  def extract_audio_url(url)
    logger.info "Extracting audio URL for: #{url}"

    # Use yt-dlp to get the best audio stream URL
    command = ['yt-dlp', '-f', 'bestaudio', '-g', '--no-playlist', url]
    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      logger.error "yt-dlp failed: #{stderr}"
      return nil
    end

    stream_url = stdout.strip
    logger.info "Extracted stream URL: #{stream_url[0..50]}..."
    stream_url
  rescue StandardError => e
    logger.error "Error extracting audio URL: #{e.message}"
    nil
  end

  # Join voice channel and play audio
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  # @param voice_channel [Discordrb::Channel] Voice channel to join
  # @param stream_url [String] Direct audio stream URL
  def play_audio(event, voice_channel, stream_url)
    logger.info "Joining voice channel: #{voice_channel.name}"

    # Connect to voice channel if not already connected
    voice_bot = event.voice
    voice_bot = bot.voice_connect(voice_channel) unless voice_bot && voice_bot.channel == voice_channel

    # Play the audio stream
    # discordrb handles ffmpeg transcoding to Opus automatically
    logger.info 'Starting audio playback...'
    voice_bot.play_url(stream_url)

    logger.info 'Audio playback finished'
  rescue StandardError => e
    logger.error "Error playing audio: #{e.message}"
    logger.error e.backtrace.join("\n")
    event.respond 'Failed to play audio. Make sure ffmpeg and libsodium are installed.'
  end
end

# Main entry point
if __FILE__ == $PROGRAM_NAME
  token = ENV.fetch('DISCORD_BOT_TOKEN', nil)

  unless token
    puts 'Error: DISCORD_BOT_TOKEN not set in environment'
    puts 'Please create a .env file with your Discord bot token:'
    puts 'DISCORD_BOT_TOKEN=your_token_here'
    exit 1
  end

  bot = MusicBot.new(token: token)
  bot.run
end
