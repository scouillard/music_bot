#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load'
require_relative 'lib/music_bot'

# Main entry point
if __FILE__ == $PROGRAM_NAME
  token = ENV.fetch('DISCORD_BOT_TOKEN', nil)

  unless token
    puts 'Error: DISCORD_BOT_TOKEN not set in environment'
    puts 'Please create a .env file with your Discord bot token:'
    puts 'DISCORD_BOT_TOKEN=your_token_here'
    exit 1
  end

  bot = MusicBot.new(token: token)
  bot.run
end
