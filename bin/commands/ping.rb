# frozen_string_literal: true

require 'discordrb'

module Commands
  class << self
    def ping(client)
      client.command(:ping, help_available: true, description: '夏羽のピングを返す。', usage: "#{ENV['PREFIX']}ping") do |event|
        current_time = DateTime.now
        message = event.respond('🏓 ピング中…')
        end_time = DateTime.now
        elapsed = ((end_time - current_time) * 24 * 60 * 60 * 1000).to_f
        message.edit("🏓 ポン！\nレイテンシ：#{elapsed}ミリ秒。")
      end
    end
  end
end
