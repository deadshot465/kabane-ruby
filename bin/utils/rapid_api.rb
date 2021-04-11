# frozen_string_literal: true

RUBY_LANG_ID = 72

module RapidAPI
  class << self
    def generate_auth_header(host)
      api_key = ENV['RAPID_API_KEY']
      {
        'content-type': 'application/json',
        'x-rapidapi-key': api_key,
        'x-rapidapi-host': host
      }
    end
  end
end
