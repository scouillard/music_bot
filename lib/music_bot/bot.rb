module MusicBot
  class Bot
    attr_reader :client, :prefix

    def initialize(token:, prefix: '$')
      @token = token
      @prefix = prefix
      @client = Discordrb::Commands::CommandBot.new(
        token: token,
        prefix: prefix
      )

      register_commands
      register_event_handlers
    end

    def run
      puts "Music Bot v#{MusicBot::VERSION} starting..."
      @client.run
    end

    def stop
      @client.stop
    end

    private

    def register_commands
      @client.command(:play, description: 'Play audio from a YouTube URL') do |event, *args|
        url = args.join(' ')

        if url.empty?
          event.respond("Usage: #{@prefix}play <youtube_url>")
        else
          Commands::PlayCommand.execute(event, url)
        end

        nil # Prevent automatic response
      end
    end

    def register_event_handlers
      @client.ready do |_event|
        puts "Bot is ready! Logged in as: #{@client.profile.username}##{@client.profile.discriminator}"
      end

      @client.message do |event|
        next unless event.message.content.start_with?(@prefix)

        # Log commands for debugging
        puts "[#{Time.now}] #{event.user.username}: #{event.message.content}"
      end
    end
  end
end
