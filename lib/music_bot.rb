require 'discordrb'
require 'dotenv/load'
require 'yaml'

require_relative 'music_bot/version'
require_relative 'music_bot/bot'
require_relative 'music_bot/commands/play_command'
require_relative 'music_bot/services/youtube_downloader'
require_relative 'music_bot/services/audio_player'
require_relative 'music_bot/models/queue'

module MusicBot
  class << self
    attr_accessor :settings

    def load_settings
      @settings = YAML.load_file(File.join(__dir__, '../config/settings.yml'))
    end
  end
end

MusicBot.load_settings
