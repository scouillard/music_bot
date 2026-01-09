module MusicBot
  module Services
    class AudioPlayer
      attr_reader :voice_bot

      def initialize(voice_bot)
        @voice_bot = voice_bot
        @current_file = nil
      end

      def play(file_path)
        raise ArgumentError, 'File does not exist' unless File.exist?(file_path)

        stop if playing?

        @current_file = file_path
        @voice_bot.play_file(file_path)
      end

      def stop
        return unless playing?

        @voice_bot.stop_playing
        cleanup_current_file
      end

      def playing?
        @voice_bot&.playing? || false
      end

      private

      def cleanup_current_file
        return unless @current_file && File.exist?(@current_file)

        File.delete(@current_file)
        @current_file = nil
      rescue StandardError => e
        puts "Warning: Failed to delete temporary file #{@current_file}: #{e.message}"
      end
    end
  end
end
