require 'spec_helper'

RSpec.describe MusicBot::Services::YoutubeDownloader do
  describe '.valid_youtube_url?' do
    context 'with valid YouTube URLs' do
      it 'returns true for standard YouTube URL' do
        url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
        expect(described_class.valid_youtube_url?(url)).to be true
      end

      it 'returns true for short YouTube URL' do
        url = 'https://youtu.be/dQw4w9WgXcQ'
        expect(described_class.valid_youtube_url?(url)).to be true
      end

      it 'returns true for YouTube URL without www' do
        url = 'https://youtube.com/watch?v=dQw4w9WgXcQ'
        expect(described_class.valid_youtube_url?(url)).to be true
      end

      it 'returns true for HTTP YouTube URL' do
        url = 'http://www.youtube.com/watch?v=dQw4w9WgXcQ'
        expect(described_class.valid_youtube_url?(url)).to be true
      end
    end

    context 'with invalid URLs' do
      it 'returns false for non-YouTube URL' do
        url = 'https://example.com'
        expect(described_class.valid_youtube_url?(url)).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.valid_youtube_url?('')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid_youtube_url?(nil)).to be false
      end

      it 'returns false for non-string input' do
        expect(described_class.valid_youtube_url?(123)).to be false
      end

      it 'returns false for malformed YouTube URL' do
        url = 'youtube.com/watch'
        expect(described_class.valid_youtube_url?(url)).to be false
      end
    end
  end

  describe '.download' do
    let(:valid_url) { 'https://www.youtube.com/watch?v=test123' }
    let(:output_dir) { './tmp/test' }

    context 'with invalid URL' do
      it 'raises ArgumentError for invalid URL' do
        expect do
          described_class.download('https://example.com', output_dir: output_dir)
        end.to raise_error(ArgumentError, 'Invalid YouTube URL')
      end
    end

    context 'with valid URL' do
      before do
        allow(FileUtils).to receive(:mkdir_p)
        allow(described_class).to receive(:`).and_return('success')
        allow(described_class).to receive(:$?).and_return(double(success?: true))
      end

      it 'creates output directory' do
        allow(described_class).to receive(:extract_file_path).and_return('/path/to/file.mp3')

        expect(FileUtils).to receive(:mkdir_p).with(output_dir)
        described_class.download(valid_url, output_dir: output_dir)
      end
    end
  end
end
