require 'spec_helper'

RSpec.describe MusicBot::Services::AudioPlayer do
  let(:voice_bot) { double('VoiceBot', playing?: false, play_file: nil, stop_playing: nil) }
  let(:player) { described_class.new(voice_bot) }

  describe '#initialize' do
    it 'sets the voice_bot' do
      expect(player.voice_bot).to eq(voice_bot)
    end
  end

  describe '#play' do
    let(:file_path) { '/tmp/test.mp3' }

    context 'when file exists' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
      end

      it 'plays the file' do
        expect(voice_bot).to receive(:play_file).with(file_path)
        player.play(file_path)
      end

      it 'stores the current file path' do
        player.play(file_path)
        expect(player.instance_variable_get(:@current_file)).to eq(file_path)
      end

      context 'when already playing' do
        before do
          allow(voice_bot).to receive(:playing?).and_return(true)
        end

        it 'stops current playback first' do
          expect(voice_bot).to receive(:stop_playing)
          player.play(file_path)
        end
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it 'raises ArgumentError' do
        expect { player.play(file_path) }.to raise_error(ArgumentError, 'File does not exist')
      end
    end
  end

  describe '#stop' do
    context 'when playing' do
      before do
        allow(voice_bot).to receive(:playing?).and_return(true)
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:delete)
        player.instance_variable_set(:@current_file, '/tmp/test.mp3')
      end

      it 'stops the voice bot' do
        expect(voice_bot).to receive(:stop_playing)
        player.stop
      end

      it 'cleans up the current file' do
        expect(File).to receive(:delete).with('/tmp/test.mp3')
        player.stop
      end
    end

    context 'when not playing' do
      before do
        allow(voice_bot).to receive(:playing?).and_return(false)
      end

      it 'does nothing' do
        expect(voice_bot).not_to receive(:stop_playing)
        player.stop
      end
    end
  end

  describe '#playing?' do
    it 'returns true when voice_bot is playing' do
      allow(voice_bot).to receive(:playing?).and_return(true)
      expect(player.playing?).to be true
    end

    it 'returns false when voice_bot is not playing' do
      allow(voice_bot).to receive(:playing?).and_return(false)
      expect(player.playing?).to be false
    end

    it 'returns false when voice_bot is nil' do
      player_without_bot = described_class.new(nil)
      expect(player_without_bot.playing?).to be false
    end
  end
end
