# frozen_string_literal: true

require 'discordrb'
require 'json'

RANDOM_RESPONSES_PATH = File.expand_path('../../assets/random_responses.json', __dir__)

module Commands
  class << self
    attr_reader :random_responses

    def load_responses
      @random_responses = JSON.parse(File.read(RANDOM_RESPONSES_PATH))
    end

    def response(client)
      client.command(:response, help_available: true,
                                description: '夏羽の返事を変更する。',
                                usage: "#{ENV['PREFIX']}response [option]",
                                required_permissions: [:administrator]) do |event|
        command_length = "#{ENV['PREFIX']}response".length + 1
        content = event.content[command_length..]
        split = content.split(' ')
        cmd = split[0]
        context = split[1..].join

        case cmd
        when 'add'
          add(context)
          event.respond('わかりました。そうします。')
        when 'remove'
          if remove?(context)
            event.respond('わかりました。これからはそうしません。')
          else
            event.respond('俺は元々そうしていません。')
          end
        end
      end
    end

    private

    def add(context)
      @random_responses << context
      File.write(RANDOM_RESPONSES_PATH, JSON.pretty_generate(@random_responses))
    end

    def remove?(context)
      result = @random_responses.delete(context)
      return false if result.nil?

      File.write(RANDOM_RESPONSES_PATH, JSON.pretty_generate(@random_responses))
      true
    end
  end
end
