module MusicBot
  module Commands
    class PlayCommand
      class << self
        def execute(event, url)
          return event.respond(message('invalid_url')) unless valid_url?(url)

          voice_channel = event.user.voice_channel
          return event.respond(message('not_in_voice')) unless voice_channel

          event.respond(message('joining_channel'))

          voice_bot = join_voice_channel(event, voice_channel)
          return event.respond('Failed to join voice channel') unless voice_bot

          play_audio_async(event, url, voice_bot)
        end

        private

        def valid_url?(url)
          Services::YoutubeDownloader.valid_youtube_url?(url)
        end

        def message(key)
          MusicBot.settings.dig('messages', key)
        end

        def play_audio_async(event, url, voice_bot)
          Thread.new do
            download_and_play(event, url, voice_bot)
          end
        end

        def download_and_play(event, url, voice_bot)
          download_dir = ENV.fetch('DOWNLOAD_DIR', './tmp')
          file_path = Services::YoutubeDownloader.download(url, output_dir: download_dir)

          title = extract_title(file_path)
          event.respond(format(message('playing'), title: title))

          player = Services::AudioPlayer.new(voice_bot)
          player.play(file_path)
        rescue StandardError => e
          handle_error(event, e)
        end

        def handle_error(event, error)
          puts "Error in play command: #{error.message}"
          puts error.backtrace
          event.respond(message('download_error'))
        end

        def join_voice_channel(event, voice_channel)
          event.voice.join_channel(voice_channel)
        rescue StandardError => e
          puts "Error joining voice channel: #{e.message}"
          nil
        end

        def extract_title(file_path)
          File.basename(file_path, '.*')
        end
      end
    end
  end
end
