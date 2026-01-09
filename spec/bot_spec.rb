# frozen_string_literal: true

require_relative '../lib/music_bot'
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

  describe 'YouTubeService' do
    let(:youtube_service) { bot_instance.youtube_service }

    describe '#valid_youtube_url?' do
      context 'with valid YouTube URLs' do
        it 'accepts youtube.com/watch URLs' do
          url = 'https://youtube.com/watch?v=dQw4w9WgXcQ'
          expect(youtube_service.valid_youtube_url?(url)).to be true
        end

        it 'accepts www.youtube.com URLs' do
          url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
          expect(youtube_service.valid_youtube_url?(url)).to be true
        end

        it 'accepts youtu.be short URLs' do
          url = 'https://youtu.be/dQw4w9WgXcQ'
          expect(youtube_service.valid_youtube_url?(url)).to be true
        end

        it 'accepts http URLs' do
          url = 'http://youtube.com/watch?v=dQw4w9WgXcQ'
          expect(youtube_service.valid_youtube_url?(url)).to be true
        end
      end

      context 'with invalid URLs' do
        it 'rejects non-YouTube URLs' do
          url = 'https://google.com'
          expect(youtube_service.valid_youtube_url?(url)).to be false
        end

        it 'rejects malformed URLs' do
          url = 'not a url'
          expect(youtube_service.valid_youtube_url?(url)).to be false
        end

        it 'rejects empty strings' do
          url = ''
          expect(youtube_service.valid_youtube_url?(url)).to be false
        end
      end
    end
  end

  describe 'QueueManager' do
    let(:queue_manager) { bot_instance.queue_manager }

    it 'starts empty' do
      expect(queue_manager.empty?).to be true
    end

    it 'adds songs to queue' do
      song = { url: 'test_url', title: 'Test Song' }
      position = queue_manager.add(song)
      expect(position).to eq(1)
      expect(queue_manager.empty?).to be false
    end
  end
end
