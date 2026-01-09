# frozen_string_literal: true

class MusicBot
  # Configuration constants for the music bot
  module Config
    # Command prefix for bot commands
    COMMAND_PREFIX = '$'

    # YouTube URL pattern for validation
    YOUTUBE_URL_PATTERN = %r{^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+}

    # Artists that are filtered by content policy
    FILTERED_ARTISTS = [
      'enima',
      'bouldat',
      '3mfrench',
      'connaisseur',
      'yvon krevé',
      'yvon kreve'
    ].freeze
  end
end
