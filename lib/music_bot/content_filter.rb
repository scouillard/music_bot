# frozen_string_literal: true

require_relative 'config'

class MusicBot
  # Content policy enforcement for filtering restricted content
  class ContentFilter
    # Check if content passes content policy
    # @param title [String] Video title to check
    # @return [Boolean] True if content is allowed, false if filtered
    def self.allowed?(title)
      return true if title.nil? || title.empty?

      title_lower = title.downcase

      # Check if any filtered artist appears in the title
      Config::FILTERED_ARTISTS.each do |artist|
        return false if title_lower.include?(artist.downcase)
      end

      true
    end
  end
end
