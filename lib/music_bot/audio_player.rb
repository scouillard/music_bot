# frozen_string_literal: true

class MusicBot
  # Manages voice channel connection and audio playback
  class AudioPlayer
    attr_reader :logger, :voice_bot, :current_channel

    def initialize(logger:)
      @logger = logger
      @voice_bot = nil
      @current_channel = nil
    end

    # Connect to a voice channel (or reuse existing connection)
    # @param voice_channel [Discordrb::Channel] Voice channel to join
    # @param bot [Discordrb::Bot] Discord bot instance
    # @return [Discordrb::Voice::VoiceBot] Voice bot connection
    def connect(voice_channel, bot)
      logger.info "Joining voice channel: #{voice_channel.name}"

      # Reuse existing connection if already in the same channel
      if @voice_bot && @current_channel == voice_channel
        logger.info "Reusing existing voice connection"
        return @voice_bot
      end

      # Create new voice connection
      logger.info "Creating new voice connection"
      @voice_bot = bot.voice_connect(voice_channel)
      @current_channel = voice_channel
      @voice_bot
    end

    # Play an audio file in the connected voice channel
    # @param audio_file [String] Path to local audio file
    # @param title [String] Song title for logging
    # @param event [Discordrb::Events::MessageEvent] Discord message event (for error messages)
    def play_file(audio_file, title = 'Unknown', event: nil)
      unless @voice_bot
        logger.error "Cannot play audio: Not connected to voice channel"
        event&.respond('❌ Not connected to a voice channel.')
        return
      end

      start_time = Time.now
      logger.info "Starting audio playback: #{title}"
      logger.info "Audio file: #{audio_file}"

      # Play the audio file
      # discordrb handles ffmpeg transcoding to Opus automatically
      @voice_bot.play_file(audio_file)

      elapsed = Time.now - start_time
      logger.info "Audio playback finished: #{title} (played for #{elapsed.round(1)} seconds)"

      # If the song ended very quickly (less than 5 seconds), something might be wrong
      if elapsed < 5
        logger.warn "Song ended very quickly (#{elapsed.round(1)}s). Possible stream issue or very short audio."
      end
    rescue StandardError => e
      logger.error "Error playing audio: #{e.message}"
      logger.error e.backtrace.join("\n")
      event&.respond('❌ Failed to play audio. Make sure ffmpeg and libsodium are installed.')
      raise
    end

    # Stop current playback
    def stop
      if @voice_bot
        logger.info "Stopping audio playback"
        @voice_bot.stop_playing
      else
        logger.warn "Cannot stop: Not connected to voice channel"
      end
    end

    # Check if connected to a voice channel
    # @return [Boolean] True if connected
    def connected?
      !@voice_bot.nil?
    end

    # Disconnect from voice channel
    def disconnect
      if @voice_bot
        logger.info "Disconnecting from voice channel"
        @voice_bot.destroy
        @voice_bot = nil
        @current_channel = nil
      end
    end

    # Reset connection state (for queue completion)
    def reset
      @voice_bot = nil
      @current_channel = nil
    end
  end
end
