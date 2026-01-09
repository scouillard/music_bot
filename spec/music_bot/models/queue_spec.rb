require 'spec_helper'

RSpec.describe MusicBot::Models::Queue do
  let(:queue) { described_class.new }

  describe '#initialize' do
    it 'creates an empty queue' do
      expect(queue.tracks).to eq([])
    end
  end

  describe '#add' do
    it 'adds a track to the queue' do
      queue.add('track1')
      expect(queue.tracks).to eq(['track1'])
    end

    it 'adds multiple tracks' do
      queue.add('track1')
      queue.add('track2')
      expect(queue.tracks).to eq(%w[track1 track2])
    end

    context 'when queue is full' do
      before do
        max_size = MusicBot.settings.dig('bot', 'max_queue_size') || 50
        max_size.times { |i| queue.add("track#{i}") }
      end

      it 'raises an error' do
        MusicBot.settings.dig('bot', 'max_queue_size') || 50
        expect { queue.add('overflow_track') }.to raise_error(/Queue is full/)
      end
    end
  end

  describe '#next' do
    it 'returns and removes the first track' do
      queue.add('track1')
      queue.add('track2')

      expect(queue.next).to eq('track1')
      expect(queue.tracks).to eq(['track2'])
    end

    it 'returns nil when queue is empty' do
      expect(queue.next).to be_nil
    end
  end

  describe '#clear' do
    it 'removes all tracks' do
      queue.add('track1')
      queue.add('track2')
      queue.clear

      expect(queue.tracks).to eq([])
    end
  end

  describe '#empty?' do
    it 'returns true when queue is empty' do
      expect(queue.empty?).to be true
    end

    it 'returns false when queue has tracks' do
      queue.add('track1')
      expect(queue.empty?).to be false
    end
  end

  describe '#size' do
    it 'returns 0 for empty queue' do
      expect(queue.size).to eq(0)
    end

    it 'returns correct size' do
      queue.add('track1')
      queue.add('track2')
      expect(queue.size).to eq(2)
    end
  end

  describe '#list' do
    it 'returns a copy of the tracks' do
      queue.add('track1')
      queue.add('track2')

      list = queue.list
      expect(list).to eq(%w[track1 track2])

      list << 'track3'
      expect(queue.tracks).to eq(%w[track1 track2])
    end
  end
end
