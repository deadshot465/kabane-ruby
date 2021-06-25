# frozen_string_literal: true

require 'discordrb'
require_relative '../utils/util'

module Commands
  class << self
    def about(client)
      client.command(:about, help_available: true, description: '夏羽の情報を表示します。', usage: "#{ENV['PREFIX']}about") do |event|
        event.channel.send_embed do |embed|
          embed.description = "The Land of Cute Boisの夏羽。\n夏羽はアニメ・マンガ「[怪物事変](https://kemonojihen-anime.com/)」の主人公です。\n夏羽バージョン0.4.4の開発者：\n**Tetsuki Syu#1250、Kirito#9286**\n制作言語・フレームワーク：\n[Ruby](https://www.ruby-lang.org/)と[Discordrb](https://github.com/shardlab/discordrb)ライブラリ。"
          embed.author = Discordrb::Webhooks::EmbedAuthor.new
          embed.author.name = '怪物事変の夏羽'
          embed.author.icon_url = client.bot_user.avatar_url
          embed.footer = Discordrb::Webhooks::EmbedFooter.new text: '夏羽ボット：リリース 0.4.4 | 2021-06-26'
          embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new url: RUBY_LOGO
          embed.colour = KABANE_COLOR
          embed.title = ''
          embed.fields = []
        end
      end
    end
  end
end
