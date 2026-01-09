#!/usr/bin/env ruby
# frozen_string_literal: true

require 'discordrb'
require 'dotenv/load'
require 'open3'
require 'logger'
require 'thread'
require 'tmpdir'
require 'fileutils'

# Discord Music Bot
# Streams YouTube audio to Discord voice channels using yt-dlp and ffmpeg
class MusicBot
  COMMAND_PREFIX = '$'
  YOUTUBE_URL_PATTERN = %r{^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+}

  # Artists that are filtered by content policy
  FILTERED_ARTISTS = [
    'enima',
    'bouldat',
    '3mfrench',
    'connaisseur',
    'yvon krevé',
    'yvon kreve'
  ].freeze

  attr_reader :bot, :logger

  # Initialize the music bot
  # @param token [String] Discord bot token
  def initialize(token:)
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO

    @bot = Discordrb::Bot.new(token: token)

    # Queue system
    @queue = []
    @queue_mutex = Mutex.new
    @current_voice_bot = nil
    @current_channel = nil
    @current_song = nil
    @playing = false

    # Temporary directory for audio files
    @temp_dir = File.join(Dir.tmpdir, 'music_bot_audio')
    FileUtils.mkdir_p(@temp_dir)
    logger.info "Temp directory for audio: #{@temp_dir}"

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

    bot.message(start_with: "#{COMMAND_PREFIX}queue") do |event|
      handle_queue_command(event)
    end

    bot.message(start_with: "#{COMMAND_PREFIX}skip") do |event|
      handle_skip_command(event)
    end
  end

  # Register event handlers
  def register_event_handlers
    bot.ready do
      logger.info "Bot logged in as: #{bot.profile.username}"
      logger.info 'Ready to play music!'
    end
  end

  # Handle the $skip command
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  def handle_skip_command(event)
    unless @playing
      event.respond '❌ Nothing is currently playing!'
      return
    end

    unless @current_voice_bot
      event.respond '❌ Not connected to a voice channel.'
      return
    end

    skipped_song = @current_song
    logger.info "Skipping current song: #{skipped_song}"

    # Stop the current playback
    @current_voice_bot.stop_playing

    if @queue.empty?
      event.respond "⏭️ Skipped: **#{skipped_song}**\n\nQueue is now empty."
    else
      event.respond "⏭️ Skipped: **#{skipped_song}**\n\nPlaying next song..."
    end
  rescue StandardError => e
    logger.error "Error in handle_skip_command: #{e.message}"
    event.respond '❌ An error occurred while trying to skip.'
  end

  # Handle the $queue command
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  def handle_queue_command(event)
    @queue_mutex.synchronize do
      if @queue.empty? && !@playing
        event.respond 'Queue is empty. Use `$play <youtube-url, playlist, or search query>` to add songs!'
        return
      end

      response = "**Music Queue** 💿\n\n"

      if @playing && @current_song
        response += "Now Playing:\n**#{@current_song}**\n"
      end

      if @queue.empty?
        response += "\nNo upcoming songs in queue." unless response.include?('Now Playing')
      else
        total_songs = @queue.length
        display_limit = 10
        songs_to_show = @queue.take(display_limit)

        response += "\n**Up Next** (#{total_songs} song#{total_songs > 1 ? 's' : ''}):\n"
        songs_to_show.each_with_index do |song, index|
          response += "`#{index + 1}.` #{song[:title]}\n"
        end

        if total_songs > display_limit
          remaining = total_songs - display_limit
          response += "\n_...and #{remaining} more song#{remaining > 1 ? 's' : ''}_"
        end
      end

      event.respond response
    end
  rescue StandardError => e
    logger.error "Error in handle_queue_command: #{e.message}"
    event.respond '❌ An error occurred while fetching the queue.'
  end

  # Handle the $play command
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  def handle_play_command(event)
    logger.info "User #{event.user.username} requested: #{event.content}"

    # Extract input from command (could be URL, playlist, or search query)
    input = extract_url_from_message(event.content)
    unless input
      event.respond '**Usage:** `$play <youtube-url, playlist, or search query>`'
      return
    end

    # Check if user is in a voice channel
    voice_channel = event.user.voice_channel
    unless voice_channel
      event.respond '❌ You must be in a voice channel to use this command!'
      return
    end

    # Check if input is a playlist URL
    if valid_youtube_url?(input) && playlist_url?(input)
      # Handle playlist
      event.respond 'Extracting playlist... This may take a moment.'
      videos = extract_playlist(input)

      unless videos
        event.respond '❌ Failed to extract playlist. Please try again.'
        return
      end

      # Filter videos through content policy
      added_count = 0
      filtered_count = 0

      videos.each do |video|
        if content_policy_check(video[:title])
          @queue_mutex.synchronize do
            @queue << { url: video[:url], title: video[:title], channel: voice_channel, event: event }
          end
          added_count += 1
        else
          filtered_count += 1
          logger.info "Filtered from playlist: #{video[:title]}"
        end
      end

      if added_count > 0
        msg = "Added **#{added_count} song#{added_count > 1 ? 's' : ''}** from playlist to queue"
        msg += "\n#{filtered_count} song#{filtered_count > 1 ? 's were' : ' was'} unavailable" if filtered_count > 0
        event.respond msg
      else
        event.respond '❌ No songs could be added from this playlist.'
        return
      end

      # Start queue processor if not already running
      process_queue unless @playing
      return
    end

    # Handle single video or search query
    url = nil
    video_title = nil

    # Check if input is a valid YouTube URL or a search query
    if valid_youtube_url?(input)
      # It's a URL, use it directly
      url = input
      event.respond 'Fetching video info...'
      video_title = extract_video_title(url) || url
    else
      # It's a search query, search YouTube for the first result
      event.respond "Searching YouTube for: **#{input}**"
      result = search_youtube(input)

      unless result
        event.respond '❌ No results found for your search query.'
        return
      end

      url = result[:url]
      video_title = result[:title]
    end

    # Check content policy
    unless content_policy_check(video_title)
      event.respond '❌ Failed to extract audio from YouTube. The video may be unavailable or restricted.'
      return
    end

    # Add to queue (store URL, not stream_url - we'll extract that right before playing)
    @queue_mutex.synchronize do
      @queue << { url: url, title: video_title, channel: voice_channel, event: event }
      queue_position = @queue.length

      if @playing
        event.respond "Added to queue at position **##{queue_position}**\n#{video_title}"
      else
        # Don't say "Playing now" here, let the queue processor announce it
      end
    end

    # Start queue processor if not already running
    process_queue unless @playing
  rescue StandardError => e
    logger.error "Error in handle_play_command: #{e.message}"
    logger.error e.backtrace.join("\n")
    event.respond '❌ An error occurred while trying to play the audio. Please try again.'
  end

  # Extract input (URL or search query) from message content
  # @param message [String] Full message content
  # @return [String, nil] Extracted input or nil
  def extract_url_from_message(message)
    # Remove the command prefix and get everything after it
    # This allows multi-word search queries like "never gonna give you up"
    input = message.sub(/^\$play\s+/i, '').strip

    input.empty? ? nil : input
  end

  # Validate YouTube URL format
  # @param url [String] URL to validate
  # @return [Boolean] True if valid YouTube URL
  def valid_youtube_url?(url)
    url.match?(YOUTUBE_URL_PATTERN)
  end

  # Check if URL is a YouTube playlist
  # @param url [String] URL to check
  # @return [Boolean] True if URL contains playlist parameter
  def playlist_url?(url)
    url.include?('list=') || url.include?('playlist?')
  end

  # Check if content passes content policy
  # @param title [String] Video title to check
  # @return [Boolean] True if content is allowed, false if filtered
  def content_policy_check(title)
    return true if title.nil? || title.empty?

    title_lower = title.downcase

    # Check if any filtered artist appears in the title
    FILTERED_ARTISTS.each do |artist|
      if title_lower.include?(artist.downcase)
        logger.info "Content policy: Filtered content detected - #{artist}"
        return false
      end
    end

    true
  end

  # Search YouTube and return first result
  # @param query [String] Search query
  # @return [Hash, nil] Hash with :url and :title, or nil on failure
  def search_youtube(query)
    logger.info "Searching YouTube for: #{query}"

    # Use ytsearch1: to get only the first result
    command = [
      'yt-dlp',
      '--get-id',
      '--get-title',
      '--no-playlist',
      "ytsearch1:#{query}"
    ]

    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      logger.error "YouTube search failed: #{stderr}"
      return nil
    end

    lines = stdout.strip.split("\n")
    if lines.length >= 2
      title = lines[0]
      video_id = lines[1]
      url = "https://www.youtube.com/watch?v=#{video_id}"
      logger.info "Found: #{title} (#{url})"
      { url: url, title: title }
    else
      logger.error "Could not parse search results"
      nil
    end
  rescue StandardError => e
    logger.error "Error searching YouTube: #{e.message}"
    nil
  end

  # Extract playlist information from YouTube
  # @param url [String] YouTube playlist URL
  # @return [Array<Hash>, nil] Array of hashes with :url and :title, or nil on failure
  def extract_playlist(url)
    logger.info "Extracting playlist from: #{url}"

    # Get playlist info: URL and title for each video
    command = [
      'yt-dlp',
      '--flat-playlist',
      '--get-id',
      '--get-title',
      '--no-warnings',
      url
    ]

    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      logger.error "Playlist extraction failed: #{stderr}"
      return nil
    end

    lines = stdout.strip.split("\n")
    videos = []

    # Lines alternate between title and video ID
    (0...lines.length).step(2) do |i|
      title = lines[i]
      video_id = lines[i + 1]
      next unless title && video_id

      video_url = "https://www.youtube.com/watch?v=#{video_id}"
      videos << { url: video_url, title: title }
    end

    logger.info "Extracted #{videos.length} videos from playlist"
    videos.empty? ? nil : videos
  rescue StandardError => e
    logger.error "Error extracting playlist: #{e.message}"
    nil
  end

  # Extract video title from YouTube using yt-dlp
  # @param url [String] YouTube video URL
  # @return [String, nil] Video title or nil on failure
  def extract_video_title(url)
    command = ['yt-dlp', '--get-title', '--no-playlist', url]
    stdout, _stderr, status = Open3.capture3(*command)

    return stdout.strip if status.success?

    nil
  rescue StandardError => e
    logger.error "Error extracting video title: #{e.message}"
    nil
  end

  # Download audio from YouTube to a temporary file
  # @param url [String] YouTube video URL
  # @return [String, nil] Path to downloaded audio file or nil on failure
  def download_audio(url)
    logger.info "Downloading audio for: #{url}"

    # Generate unique filename
    timestamp = Time.now.to_i
    output_file = File.join(@temp_dir, "audio_#{timestamp}.%(ext)s")

    # Download audio using yt-dlp
    # Use opus format when possible for best Discord compatibility and quality
    command = [
      'yt-dlp',
      '-f', 'bestaudio/best',
      '--extract-audio',
      '--audio-format', 'opus',
      '--audio-quality', '0',
      '--no-playlist',
      '-o', output_file,
      url
    ]

    # Add cookies if available
    cookies_file = File.expand_path('~/.config/yt-dlp/cookies.txt')
    if File.exist?(cookies_file)
      command.insert(-2, '--cookies', cookies_file)
      logger.info "Using cookies from: #{cookies_file}"
    end

    logger.info "Starting download..."
    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      logger.error "yt-dlp download failed: #{stderr}"
      return nil
    end

    # Find the downloaded file
    downloaded_file = Dir.glob(File.join(@temp_dir, "audio_#{timestamp}.*")).first

    if downloaded_file && File.exist?(downloaded_file)
      file_size = File.size(downloaded_file) / 1024.0 / 1024.0
      logger.info "Downloaded audio: #{downloaded_file} (#{file_size.round(2)} MB)"
      downloaded_file
    else
      logger.error "Downloaded file not found"
      nil
    end
  rescue StandardError => e
    logger.error "Error downloading audio: #{e.message}"
    nil
  end

  # Process the queue and play songs one after another
  def process_queue
    Thread.new do
      loop do
        song = nil

        @queue_mutex.synchronize do
          break if @queue.empty?

          @playing = true
          song = @queue.shift
          @current_song = song[:title]
        end

        break unless song

        audio_file = nil
        begin
          logger.info "Now playing from queue: #{song[:title]}"

          # Announce that the song is starting
          song[:event].respond "Now Playing:\n**#{song[:title]}**"

          # Download audio file to avoid buffering/streaming issues
          logger.info "Downloading audio for: #{song[:url]}"
          audio_file = download_audio(song[:url])

          unless audio_file
            logger.error "Failed to download audio for: #{song[:title]}"
            song[:event].respond "❌ Failed to play: **#{song[:title]}**\n\nCould not download audio."
            next
          end

          # Play the audio from local file
          play_audio(song[:event], song[:channel], audio_file, song[:title])

          logger.info "Finished playing: #{song[:title]}"
        rescue StandardError => e
          logger.error "Error playing queued song: #{e.message}"
          logger.error e.backtrace.join("\n")
          song[:event].respond "❌ Failed to play: **#{song[:title]}**"
        ensure
          # Clean up the temporary audio file
          if audio_file && File.exist?(audio_file)
            begin
              File.delete(audio_file)
              logger.info "Cleaned up temp file: #{audio_file}"
            rescue StandardError => e
              logger.warn "Failed to delete temp file #{audio_file}: #{e.message}"
            end
          end
        end
      end

      # Queue is empty, mark as not playing
      @queue_mutex.synchronize do
        @playing = false
        @current_voice_bot = nil
        @current_channel = nil
        @current_song = nil
      end

      logger.info 'Queue finished, no more songs to play'
    end
  end

  # Join voice channel and play audio
  # @param event [Discordrb::Events::MessageEvent] Discord message event
  # @param voice_channel [Discordrb::Channel] Voice channel to join
  # @param audio_file [String] Path to local audio file
  # @param title [String] Song title for logging
  def play_audio(event, voice_channel, audio_file, title = 'Unknown')
    start_time = Time.now
    logger.info "Joining voice channel: #{voice_channel.name}"

    # Connect to voice channel if not already connected
    if @current_voice_bot && @current_channel == voice_channel
      voice_bot = @current_voice_bot
      logger.info "Reusing existing voice connection"
    else
      logger.info "Creating new voice connection"
      voice_bot = bot.voice_connect(voice_channel)
      @current_voice_bot = voice_bot
      @current_channel = voice_channel
    end

    # Play the audio file
    # discordrb handles ffmpeg transcoding to Opus automatically
    # Playing from local file eliminates network buffering issues
    logger.info "Starting audio playback: #{title}"
    logger.info "Audio file: #{audio_file}"

    voice_bot.play_file(audio_file)

    elapsed = Time.now - start_time
    logger.info "Audio playback finished: #{title} (played for #{elapsed.round(1)} seconds)"

    # If the song ended very quickly (less than 5 seconds), something might be wrong
    if elapsed < 5
      logger.warn "Song ended very quickly (#{elapsed.round(1)}s). Possible stream issue or very short audio."
    end
  rescue StandardError => e
    logger.error "Error playing audio: #{e.message}"
    logger.error e.backtrace.join("\n")
    event.respond '❌ Failed to play audio. Make sure ffmpeg and libsodium are installed.'
    raise
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
