# frozen_string_literal: true

require_relative '../bot'
require_relative 'spec_helper'

RSpec.describe MusicBot do
  let(:test_token) { 'test_discord_token_123' }
  let(:bot_instance) { described_class.new(token: test_token) }

  describe '#initialize' do
    it 'creates a new MusicBot instance' do
      expect(bot_instance).to be_a(MusicBot)
    end

    it 'initializes a Discordrb bot' do
      expect(bot_instance.bot).to be_a(Discordrb::Bot)
    end

    it 'initializes a logger' do
      expect(bot_instance.logger).to be_a(Logger)
    end
  end

  describe '#extract_url_from_message' do
    it 'extracts URL from valid $play command' do
      message = '$play https://youtube.com/watch?v=dQw4w9WgXcQ'
      url = bot_instance.send(:extract_url_from_message, message)
      expect(url).to eq('https://youtube.com/watch?v=dQw4w9WgXcQ')
    end

    it 'returns nil when no URL is provided' do
      message = '$play'
      url = bot_instance.send(:extract_url_from_message, message)
      expect(url).to be_nil
    end

    it 'handles multiple spaces in command' do
      message = '$play  https://youtube.com/watch?v=test123'
      url = bot_instance.send(:extract_url_from_message, message)
      expect(url).to eq('https://youtube.com/watch?v=test123')
    end
  end

  describe '#valid_youtube_url?' do
    context 'with valid YouTube URLs' do
      it 'accepts youtube.com/watch URLs' do
        url = 'https://youtube.com/watch?v=dQw4w9WgXcQ'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be true
      end

      it 'accepts www.youtube.com URLs' do
        url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be true
      end

      it 'accepts youtu.be short URLs' do
        url = 'https://youtu.be/dQw4w9WgXcQ'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be true
      end

      it 'accepts http URLs' do
        url = 'http://youtube.com/watch?v=dQw4w9WgXcQ'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be true
      end
    end

    context 'with invalid URLs' do
      it 'rejects non-YouTube URLs' do
        url = 'https://google.com'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be false
      end

      it 'rejects malformed URLs' do
        url = 'not a url'
        expect(bot_instance.send(:valid_youtube_url?, url)).to be false
      end

      it 'rejects empty strings' do
        url = ''
        expect(bot_instance.send(:valid_youtube_url?, url)).to be false
      end
    end
  end

  describe '#extract_audio_url' do
    context 'when yt-dlp succeeds' do
      it 'returns the audio stream URL' do
        youtube_url = 'https://youtube.com/watch?v=dQw4w9WgXcQ'
        stream_url = 'https://example.com/audio_stream.m4a'

        allow(Open3).to receive(:capture3)
          .with('yt-dlp', '-f', 'bestaudio', '-g', '--no-playlist', youtube_url)
          .and_return(["#{stream_url}\n", '', double(success?: true)])

        result = bot_instance.send(:extract_audio_url, youtube_url)
        expect(result).to eq(stream_url)
      end
    end

    context 'when yt-dlp fails' do
      it 'returns nil on failure' do
        youtube_url = 'https://youtube.com/watch?v=invalid'

        allow(Open3).to receive(:capture3)
          .with('yt-dlp', '-f', 'bestaudio', '-g', '--no-playlist', youtube_url)
          .and_return(['', 'ERROR: Video unavailable', double(success?: false)])

        result = bot_instance.send(:extract_audio_url, youtube_url)
        expect(result).to be_nil
      end

      it 'handles exceptions gracefully' do
        youtube_url = 'https://youtube.com/watch?v=test'

        allow(Open3).to receive(:capture3).and_raise(StandardError.new('Command failed'))

        result = bot_instance.send(:extract_audio_url, youtube_url)
        expect(result).to be_nil
      end
    end
  end
end
