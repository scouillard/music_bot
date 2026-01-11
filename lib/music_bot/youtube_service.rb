# frozen_string_literal: true

require 'open3'
require 'json'
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
      cookie_file = File.join(temp_dir, "cookies_#{timestamp}.txt")

      # Step 1: Use Puppeteer to navigate to YouTube and extract cookies
      # This bypasses bot detection by using a real headless browser
      logger.info 'Using headless browser to establish session...'
      extractor_script = File.join(File.dirname(__FILE__), 'youtube_extractor.js')

      puppeteer_cmd = ['node', extractor_script, url, cookie_file]
      stdout, stderr, status = Open3.capture3(*puppeteer_cmd)

      unless status.success?
        logger.error "Puppeteer extraction failed: #{stderr}"
        logger.error "Stdout: #{stdout}"
        # Fall back to direct yt-dlp if Puppeteer fails
        return download_audio_fallback(url, temp_dir, timestamp)
      end

      begin
        result = JSON.parse(stdout)
        logger.info "Browser session established: #{result['title']}"
        logger.info "Cookies saved to: #{result['cookieFile']}"
      rescue JSON::ParserError => e
        logger.error "Failed to parse Puppeteer output: #{e.message}"
        return download_audio_fallback(url, temp_dir, timestamp)
      end

      # Step 2: Use yt-dlp with the cookies from the browser session
      command = [
        'yt-dlp',
        '-f', 'bestaudio/best',
        '--extract-audio',
        '--audio-format', 'opus',
        '--audio-quality', '0',
        '--no-playlist',
        '--cookies', cookie_file,
        '-o', output_file,
        url
      ]

      logger.info 'Starting download with browser session cookies...'
      _stdout, stderr, status = Open3.capture3(*command)

      # Clean up cookie file
      File.delete(cookie_file) if File.exist?(cookie_file)

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
        logger.error 'Downloaded file not found'
        nil
      end
    rescue StandardError => e
      logger.error "Error downloading audio: #{e.message}"
      logger.error e.backtrace.join("\n")
      # Clean up cookie file on error
      File.delete(cookie_file) if File.exist?(cookie_file)
      nil
    end

    # Fallback method if Puppeteer fails - try direct yt-dlp
    def download_audio_fallback(url, temp_dir, timestamp)
      logger.info 'Falling back to direct yt-dlp without browser session...'
      output_file = File.join(temp_dir, "audio_#{timestamp}.%(ext)s")

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

      _stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        logger.error "Fallback yt-dlp also failed: #{stderr}"
        return nil
      end

      downloaded_file = Dir.glob(File.join(temp_dir, "audio_#{timestamp}.*")).first
      if downloaded_file && File.exist?(downloaded_file)
        file_size = File.size(downloaded_file) / 1024.0 / 1024.0
        logger.info "Downloaded audio (fallback): #{downloaded_file} (#{file_size.round(2)} MB)"
        downloaded_file
      else
        nil
      end
    rescue StandardError => e
      logger.error "Fallback error: #{e.message}"
      nil
    end
  end
end
