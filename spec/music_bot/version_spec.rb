require 'spec_helper'

RSpec.describe MusicBot do
  describe 'VERSION' do
    it 'has a version number' do
      expect(MusicBot::VERSION).not_to be_nil
    end

    it 'is a string' do
      expect(MusicBot::VERSION).to be_a(String)
    end

    it 'follows semantic versioning format' do
      expect(MusicBot::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end
  end
end
