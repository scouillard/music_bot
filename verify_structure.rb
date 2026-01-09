#!/usr/bin/env ruby

# Simple script to verify code structure without requiring Discord gems

require 'English'
puts 'Verifying project structure...'
puts

# Check all required files exist
required_files = [
  'lib/music_bot.rb',
  'lib/music_bot/version.rb',
  'lib/music_bot/bot.rb',
  'lib/music_bot/commands/play_command.rb',
  'lib/music_bot/services/youtube_downloader.rb',
  'lib/music_bot/services/audio_player.rb',
  'lib/music_bot/models/queue.rb',
  'config/settings.yml',
  'bin/bot',
  'Gemfile',
  '.env.example',
  '.gitignore',
  'README.md',
  'docs/SETUP.md',
  'docs/conventions.md'
]

missing_files = []
required_files.each do |file|
  if File.exist?(file)
    puts "✓ #{file}"
  else
    puts "✗ #{file} (MISSING)"
    missing_files << file
  end
end

puts
if missing_files.empty?
  puts '✓ All required files present'
else
  puts "✗ Missing #{missing_files.length} file(s)"
  exit 1
end

puts
puts 'Checking Ruby syntax...'
ruby_files = Dir.glob('lib/**/*.rb') + Dir.glob('spec/**/*.rb')

syntax_errors = []
ruby_files.each do |file|
  output = `ruby -c #{file} 2>&1`
  if $CHILD_STATUS.success?
    puts "✓ #{file}"
  else
    puts "✗ #{file}"
    puts "  #{output}"
    syntax_errors << file
  end
end

puts
if syntax_errors.empty?
  puts '✓ All Ruby files have valid syntax'
else
  puts "✗ #{syntax_errors.length} file(s) have syntax errors"
  exit 1
end

puts
puts '✓ Project structure verification complete!'
puts
puts 'Next steps:'
puts '1. Run: bundle install'
puts '2. Run: bundle exec rspec'
puts '3. Create .env file with your Discord bot token'
puts '4. Run: ./bin/bot'
