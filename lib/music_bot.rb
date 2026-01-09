# frozen_string_literal: true

require 'discordrb'
require 'logger'
require 'tmpdir'
require 'fileutils'

# Require all component files
require_relative 'music_bot/config'
require_relative 'music_bot/content_filter'
require_relative 'music_bot/youtube_service'
require_relative 'music_bot/queue_manager'
require_relative 'music_bot/audio_player'
require_relative 'music_bot/commands'

# Discord Music Bot
# Streams YouTube audio to Discord voice channels using yt-dlp and ffmpeg
class MusicBot
  attr_reader :bot, :logger, :queue_manager, :youtube_service, :audio_player

  # Initialize the music bot
  # @param token [String] Discord bot token
  def initialize(token:)
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO

    @bot = Discordrb::Bot.new(token: token)

    # Initialize components
    @queue_manager = QueueManager.new
    @youtube_service = YouTubeService.new(logger: logger)
    @audio_player = AudioPlayer.new(logger: logger)

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

  # Process the queue and play songs one after another
  # This is called by commands when they add songs to the queue
  def process_queue
    Thread.new do
      loop do
        song = queue_manager.next_song
        break unless song

        audio_file = nil
        begin
          logger.info "Now playing from queue: #{song[:title]}"

          # Announce that the song is starting
          song[:event].respond "Now Playing:\n**#{song[:title]}**"

          # Download audio file to avoid buffering/streaming issues
          audio_file = youtube_service.download_audio(song[:url], @temp_dir)

          unless audio_file
            logger.error "Failed to download audio for: #{song[:title]}"
            song[:event].respond "❌ Failed to play: **#{song[:title]}**\n\nCould not download audio."
            next
          end

          # Connect to voice channel and play the audio
          audio_player.connect(song[:channel], bot)
          audio_player.play_file(audio_file, song[:title], event: song[:event])

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

      # Queue is empty, mark as not playing and reset audio player
      queue_manager.reset_playing_state
      audio_player.reset

      logger.info 'Queue finished, no more songs to play'
    end
  end

  private

  # Register command handlers
  def register_commands
    bot.message(start_with: "#{Config::COMMAND_PREFIX}play") do |event|
      command = PlayCommand.new(event: event, music_bot: self, logger: logger)
      command.execute
    end

    bot.message(start_with: "#{Config::COMMAND_PREFIX}queue") do |event|
      command = QueueCommand.new(event: event, music_bot: self, logger: logger)
      command.execute
    end

    bot.message(start_with: "#{Config::COMMAND_PREFIX}skip") do |event|
      command = SkipCommand.new(event: event, music_bot: self, logger: logger)
      command.execute
    end
  end

  # Register event handlers
  def register_event_handlers
    bot.ready do
      logger.info "Bot logged in as: #{bot.profile.username}"
      logger.info 'Ready to play music!'
    end
  end
end
