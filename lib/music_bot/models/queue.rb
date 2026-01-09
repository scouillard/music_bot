module MusicBot
  module Models
    class Queue
      attr_reader :tracks

      def initialize
        @tracks = []
      end

      def add(track)
        max_size = MusicBot.settings.dig('bot', 'max_queue_size') || 50

        raise "Queue is full (maximum #{max_size} tracks)" if @tracks.length >= max_size

        @tracks << track
      end

      def next
        @tracks.shift
      end

      def clear
        @tracks.clear
      end

      def empty?
        @tracks.empty?
      end

      def size
        @tracks.length
      end

      def list
        @tracks.dup
      end
    end
  end
end
