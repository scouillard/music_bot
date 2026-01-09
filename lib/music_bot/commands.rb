# frozen_string_literal: true

require_relative 'content_filter'

class MusicBot
  # Base command class with common interface
  class BaseCommand
    attr_reader :event, :music_bot, :logger

    def initialize(event:, music_bot:, logger:)
      @event = event
      @music_bot = music_bot
      @logger = logger
    end

    def execute
      raise NotImplementedError, "#{self.class} must implement #execute"
    end

    protected

    def respond(message)
      event.respond(message)
    end

    def user_voice_channel
      event.user.voice_channel
    end
  end

  # Command to handle $play requests
  class PlayCommand < BaseCommand
    def execute
      logger.info "User #{event.user.username} requested: #{event.content}"

      # Extract input from command (could be URL, playlist, or search query)
      input = extract_input
      unless input
        respond '**Usage:** `$play <youtube-url, playlist, or search query>`'
        return
      end

      # Check if user is in a voice channel
      voice_channel = user_voice_channel
      unless voice_channel
        respond '❌ You must be in a voice channel to use this command!'
        return
      end

      # Check if input is a playlist URL
      if music_bot.youtube_service.valid_youtube_url?(input) && music_bot.youtube_service.playlist_url?(input)
        handle_playlist(input, voice_channel)
        return
      end

      # Handle single video or search query
      handle_single_video_or_search(input, voice_channel)
    rescue StandardError => e
      logger.error "Error in PlayCommand: #{e.message}"
      logger.error e.backtrace.join("\n")
      respond '❌ An error occurred while trying to play the audio. Please try again.'
    end

    private

    def extract_input
      # Remove the command prefix and get everything after it
      input = event.content.sub(/^\$play\s+/i, '').strip
      input.empty? ? nil : input
    end

    def handle_playlist(url, voice_channel)
      respond 'Extracting playlist... This may take a moment.'
      videos = music_bot.youtube_service.extract_playlist(url)

      unless videos
        respond '❌ Failed to extract playlist. Please try again.'
        return
      end

      # Filter videos through content policy
      added_count = 0
      filtered_count = 0

      videos.each do |video|
        if ContentFilter.allowed?(video[:title])
          music_bot.queue_manager.add({ url: video[:url], title: video[:title], channel: voice_channel, event: event })
          added_count += 1
        else
          filtered_count += 1
          logger.info "Filtered from playlist: #{video[:title]}"
        end
      end

      if added_count > 0
        msg = "Added **#{added_count} song#{added_count > 1 ? 's' : ''}** from playlist to queue"
        msg += "\n#{filtered_count} song#{filtered_count > 1 ? 's were' : ' was'} unavailable" if filtered_count > 0
        respond msg
      else
        respond '❌ No songs could be added from this playlist.'
        return
      end

      # Start queue processor if not already running
      music_bot.process_queue unless music_bot.queue_manager.playing?
    end

    def handle_single_video_or_search(input, voice_channel)
      url = nil
      video_title = nil

      # Check if input is a valid YouTube URL or a search query
      if music_bot.youtube_service.valid_youtube_url?(input)
        # It's a URL, use it directly
        url = input
        respond 'Fetching video info...'
        video_title = music_bot.youtube_service.extract_video_title(url) || url
      else
        # It's a search query, search YouTube for the first result
        respond "Searching YouTube for: **#{input}**"
        result = music_bot.youtube_service.search(input)

        unless result
          respond '❌ No results found for your search query.'
          return
        end

        url = result[:url]
        video_title = result[:title]
      end

      # Check content policy
      unless ContentFilter.allowed?(video_title)
        respond '❌ Failed to extract audio from YouTube. The video may be unavailable or restricted.'
        return
      end

      # Add to queue
      position = music_bot.queue_manager.add({ url: url, title: video_title, channel: voice_channel, event: event })

      if music_bot.queue_manager.playing?
        respond "Added to queue at position **##{position}**\n#{video_title}"
      end

      # Start queue processor if not already running
      music_bot.process_queue unless music_bot.queue_manager.playing?
    end
  end

  # Command to display the current queue
  class QueueCommand < BaseCommand
    def execute
      if music_bot.queue_manager.empty? && !music_bot.queue_manager.playing?
        respond 'Queue is empty. Use `$play <youtube-url, playlist, or search query>` to add songs!'
        return
      end

      response = "**Music Queue** 💿\n\n"

      # Show currently playing song
      if music_bot.queue_manager.playing?
        current_song = music_bot.queue_manager.current
        response += "Now Playing:\n**#{current_song}**\n" if current_song
      end

      # Show upcoming songs
      queue_list = music_bot.queue_manager.list
      if queue_list.empty?
        response += "\nNo upcoming songs in queue." unless response.include?('Now Playing')
      else
        total_songs = queue_list.length
        display_limit = 10
        songs_to_show = queue_list.take(display_limit)

        response += "\n**Up Next** (#{total_songs} song#{total_songs > 1 ? 's' : ''}):\n"
        songs_to_show.each_with_index do |song, index|
          response += "`#{index + 1}.` #{song[:title]}\n"
        end

        if total_songs > display_limit
          remaining = total_songs - display_limit
          response += "\n_...and #{remaining} more song#{remaining > 1 ? 's' : ''}_"
        end
      end

      respond response
    rescue StandardError => e
      logger.error "Error in QueueCommand: #{e.message}"
      respond '❌ An error occurred while fetching the queue.'
    end
  end

  # Command to skip the current song
  class SkipCommand < BaseCommand
    def execute
      unless music_bot.queue_manager.playing?
        respond '❌ Nothing is currently playing!'
        return
      end

      unless music_bot.audio_player.connected?
        respond '❌ Not connected to a voice channel.'
        return
      end

      skipped_song = music_bot.queue_manager.current
      logger.info "Skipping current song: #{skipped_song}"

      # Stop the current playback
      music_bot.audio_player.stop

      if music_bot.queue_manager.empty?
        respond "⏭️ Skipped: **#{skipped_song}**\n\nQueue is now empty."
      else
        respond "⏭️ Skipped: **#{skipped_song}**\n\nPlaying next song..."
      end
    rescue StandardError => e
      logger.error "Error in SkipCommand: #{e.message}"
      respond '❌ An error occurred while trying to skip.'
    end
  end
end
