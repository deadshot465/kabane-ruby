# frozen_string_literal: true

require 'dotenv'
require 'discordrb'
require_relative 'commands/about'
require_relative 'commands/admin_commands'
require_relative 'commands/commands'
require_relative 'commands/eval'
require_relative 'commands/owoify'
require_relative 'commands/ping'

Dotenv.load('.env', '../.env')
client = Discordrb::Commands::CommandBot.new(token: ENV['TOKEN'],
                                             prefix: ENV['PREFIX'],
                                             command_doesnt_exist_message: '俺はこのコマンドを見つけていなかった。',
                                             ignore_bots: true)
PRESENCES = %w[クレープ ピザ お菓子 稽古中 織との喧嘩 ミッション 依頼 親探し].freeze
COMMANDS = [
  Commands.method(:about),
  Commands.method(:eval),
  Commands.method(:owoify),
  Commands.method(:ping),
  Commands.method(:response)
].freeze

Commands.load_responses

client.ready({}) do |_|
  client.update_status('online', PRESENCES[rand(PRESENCES.length)], nil)
  Thread.new do
    loop do
      sleep(60 * 60)
      client.update_status('online', PRESENCES[rand(PRESENCES.length)], nil)
    end
  end
end

client.mention({}) do |event|
  author_mention = "<@!#{event.author.id}>"
  random_response = Commands.random_responses[rand(Commands.random_responses.length)].gsub('{user}', author_mention)
  event.respond(random_response)
end

COMMANDS.each { |cmd| cmd.call(client) }

client.run
