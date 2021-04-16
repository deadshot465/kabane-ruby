# frozen_string_literal: true

require 'discordrb'
require 'owoify_rb'
require_relative '../utils/util'

module Commands
  class << self
    def owoify(client)
      client.command(:owoify, help_available: true, description: '夏羽に頼んで、入力したメッセージを赤ちゃんみたいな言葉を変えます。',
                              usage: "#{ENV['PREFIX']}owoify <テキスト>",
                              min_args: 1,
                              arg_types: [String]) do |event|
        command_length = "#{ENV['PREFIX']}owoify ".length
        content = event.content[command_length..]
        event.respond(Owoify.owoify(content, 'uwu'))
      end
    end
  end
end
