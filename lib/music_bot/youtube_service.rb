# frozen_string_literal: true

require 'open3'
require_relative 'config'

class MusicBot
  # Service for all YouTube and yt-dlp interactions
  class YouTubeService
    attr_reader :logger

    def initialize(logger:)
      @logger = logger
    end

    # Validate YouTube URL format
    # @param url [String] URL to validate
    # @return [Boolean] True if valid YouTube URL
    def valid_youtube_url?(url)
      url.match?(Config::YOUTUBE_URL_PATTERN)
    end

    # Check if URL is a YouTube playlist
    # @param url [String] URL to check
    # @return [Boolean] True if URL contains playlist parameter
    def playlist_url?(url)
      url.include?('list=') || url.include?('playlist?')
    end

    # Search YouTube and return first result
    # @param query [String] Search query
    # @return [Hash, nil] Hash with :url and :title, or nil on failure
    def search(query)
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
    # @param temp_dir [String] Directory to store downloaded audio
    # @return [String, nil] Path to downloaded audio file or nil on failure
    def download_audio(url, temp_dir)
      logger.info "Downloading audio for: #{url}"

      # Generate unique filename
      timestamp = Time.now.to_i
      output_file = File.join(temp_dir, "audio_#{timestamp}.%(ext)s")

      # Download audio using yt-dlp
      # Use opus format when possible for best Discord compatibility and quality
      command = [
        'yt-dlp',
        '-f', 'bestaudio/best',
        '--extract-audio',
        '--audio-format', 'opus',
        '--audio-quality', '0',
        '--no-playlist',
        '--remote-components', 'ejs:github',  # Required for Deno-based YouTube extraction
        '-o', output_file
      ]

      # Make cookies optional - try without them first (like local setup)
      # YouTube detection is less aggressive without cookies from data center IPs
      # cookies_locations = [
      #   '/app/data/cookies.txt',
      #   File.expand_path('~/.config/yt-dlp/cookies.txt')
      # ]
      #
      # cookies_file = cookies_locations.find { |f| File.exist?(f) }
      #
      # if cookies_file
      #   command.insert(-1, '--cookies', cookies_file)
      #   logger.info "Using cookies from: #{cookies_file}"
      # end

      # Use newer bypass methods that work better from data center IPs
      # tv_embedded client is less strict about bot detection
      command.insert(-1, '--extractor-args', 'youtube:player_client=tv_embedded')
      command.insert(-1, '--extractor-args', 'youtube:player_skip=webpage')

      # Add realistic mobile user agent to reduce bot detection
      command.insert(-1, '--user-agent', 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')

      command << url

      logger.info "Starting download..."
      _stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        logger.error "yt-dlp download failed: #{stderr}"
        return nil
      end

      # Find the downloaded file
      downloaded_file = Dir.glob(File.join(temp_dir, "audio_#{timestamp}.*")).first

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
  end
end
