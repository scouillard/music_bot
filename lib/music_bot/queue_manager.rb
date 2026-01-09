# frozen_string_literal: true

require 'thread'

class MusicBot
  # Thread-safe queue management for song playback
  class QueueManager
    attr_reader :mutex

    def initialize
      @queue = []
      @mutex = Mutex.new
      @current_song = nil
      @playing = false
    end

    # Add a song to the queue
    # @param song_hash [Hash] Song data with :url, :title, :channel, :event
    # @return [Integer] Position in queue
    def add(song_hash)
      @mutex.synchronize do
        @queue << song_hash
        @queue.length
      end
    end

    # Get and remove the next song from queue
    # @return [Hash, nil] Next song or nil if queue empty
    def next_song
      @mutex.synchronize do
        if @queue.empty?
          @playing = false
          @current_song = nil
          return nil
        end

        @playing = true
        song = @queue.shift
        @current_song = song[:title]
        song
      end
    end

    # Get current playing song
    # @return [String, nil] Current song title or nil
    def current
      @mutex.synchronize { @current_song }
    end

    # Set current playing song
    # @param title [String] Song title
    def current=(title)
      @mutex.synchronize { @current_song = title }
    end

    # Get queue contents for display
    # @return [Array<Hash>] Array of song hashes
    def list
      @mutex.synchronize { @queue.dup }
    end

    # Check if queue is empty
    # @return [Boolean] True if queue empty
    def empty?
      @mutex.synchronize { @queue.empty? }
    end

    # Get queue size
    # @return [Integer] Number of songs in queue
    def size
      @mutex.synchronize { @queue.length }
    end

    # Clear the entire queue
    def clear
      @mutex.synchronize do
        @queue.clear
        @playing = false
        @current_song = nil
      end
    end

    # Set playing state
    # @param state [Boolean] Playing state
    def playing=(state)
      @mutex.synchronize { @playing = state }
    end

    # Get playing state
    # @return [Boolean] True if currently playing
    def playing?
      @mutex.synchronize { @playing }
    end

    # Reset playing state (called when queue finishes)
    def reset_playing_state
      @mutex.synchronize do
        @playing = false
        @current_song = nil
      end
    end
  end
end
