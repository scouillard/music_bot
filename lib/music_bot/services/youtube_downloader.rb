require 'English'
module MusicBot
  module Services
    class YoutubeDownloader
      YOUTUBE_REGEX = %r{^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+}

      class << self
        def download(url, output_dir:)
          raise ArgumentError, 'Invalid YouTube URL' unless valid_youtube_url?(url)

          FileUtils.mkdir_p(output_dir)

          output_template = File.join(output_dir, '%(title)s.%(ext)s')
          command = build_download_command(url, output_template)

          output = `#{command} 2>&1`

          raise "Download failed: #{output}" unless $CHILD_STATUS.success?

          extract_file_path(output, output_dir)
        end

        def valid_youtube_url?(url)
          return false unless url.is_a?(String)

          url.match?(YOUTUBE_REGEX)
        end

        private

        def build_download_command(url, output_template)
          settings = MusicBot.settings['bot']
          quality = settings['audio_quality'] || 'bestaudio'

          # Escape the URL and output template for shell safety
          escaped_url = url.shellescape
          escaped_template = output_template.shellescape

          "yt-dlp -f #{quality} -x --audio-format mp3 -o #{escaped_template} #{escaped_url}"
        end

        def extract_file_path(output, output_dir)
          # Look for the destination file in yt-dlp output
          match = output.match(/\[ExtractAudio\] Destination: (.+)$/) ||
                  output.match(/\[download\] (.+) has already been downloaded/)

          if match
            match[1].strip
          else
            # Fallback: find the most recent mp3 file in output directory
            files = Dir.glob(File.join(output_dir, '*.mp3')).sort_by { |f| File.mtime(f) }
            files.last || raise('Could not determine downloaded file path')
          end
        end
      end
    end
  end
end
