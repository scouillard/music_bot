require 'spec_helper'

RSpec.describe MusicBot::Bot do
  let(:token) { 'test_token' }
  let(:prefix) { '$' }
  let(:bot) { described_class.new(token: token, prefix: prefix) }

  describe '#initialize' do
    it 'sets the token' do
      expect(bot.instance_variable_get(:@token)).to eq(token)
    end

    it 'sets the prefix' do
      expect(bot.prefix).to eq(prefix)
    end

    it 'creates a Discord client' do
      expect(bot.client).to be_a(Discordrb::Commands::CommandBot)
    end

    it 'uses default prefix when not provided' do
      default_bot = described_class.new(token: token)
      expect(default_bot.prefix).to eq('$')
    end
  end

  describe '#run' do
    it 'starts the bot client' do
      expect(bot.client).to receive(:run)
      bot.run
    end
  end

  describe '#stop' do
    it 'stops the bot client' do
      expect(bot.client).to receive(:stop)
      bot.stop
    end
  end
end
