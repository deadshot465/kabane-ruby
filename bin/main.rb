# frozen_string_literal: true

require 'dotenv'
require 'discordrb'
require 'owoify_rb'
require 'thread'

Dotenv.load('.env', '../.env')
client = Discordrb::Commands::CommandBot.new(token: ENV['TOKEN'],
                                             prefix: ENV['PREFIX'],
                                             command_doesnt_exist_message: '俺はこのコマンドを見つけていなかった。',
                                             ignore_bots: true)
PRESENCES = %w[クレープ ピザ お菓子 稽古中 織との喧嘩 ミッション 依頼 親探し]
RANDOM_RESPONSES = %w[お役に立ててよかったです、{user}。 晶がいないと、織とよく喧嘩してしまうので、俺は困ります。 ピザというものは織が紹介してくれた食べ物です。とても美味しいです。{user}、君も試しに食べないか？ 俺はもっと強くならなきゃ。 飯生さんは信用できない。君の気をつけた方がいいよ、{user}。]

client.ready({}) do |_|
  client.update_status('online', PRESENCES[rand(PRESENCES.length)], nil)
  Thread.new do ||
    loop do
      sleep(60 * 60)
      client.update_status('online', PRESENCES[rand(PRESENCES.length)], nil)
    end
  end
end

client.mention({}) do |event|
  author_mention = "<@!#{event.author.id}>"
  random_response = RANDOM_RESPONSES[rand(RANDOM_RESPONSES.length)].gsub('{user}', author_mention)
  event.respond(random_response)
end

client.command(:ping, help_available: true, description: '夏羽のピングを返す。', usage: "#{ENV['PREFIX']}ping") do |event|
  current_time = DateTime.now
  message = event.respond('🏓 ピング中…')
  end_time = DateTime.now
  elapsed = ((end_time - current_time) * 24 * 60 * 60 * 1000).to_f
  message.edit("🏓 ポン！\nレイテンシ：#{elapsed}ミリ秒。")
end

client.command(:about, help_available: true, description: '夏羽の情報を表示します。', usage: "#{ENV['PREFIX']}about") do |event|
  event.channel.send_embed do |embed|
    embed.description = "The Land of Cute Boisの夏羽。\n夏羽はアニメ・マンガ「[怪物事変](https://kemonojihen-anime.com/)」の主人公です。\n夏羽バージョン0.1の開発者：\n**Tetsuki Syu#1250、Kirito#9286**\n制作言語・フレームワーク：\n[Ruby](https://www.ruby-lang.org/)と[Discordrb](https://github.com/shardlab/discordrb)ライブラリ。"
    embed.author = Discordrb::Webhooks::EmbedAuthor.new
    embed.author.name = '怪物事変の夏羽'
    embed.author.icon_url = client.bot_user.avatar_url
    embed.footer = Discordrb::Webhooks::EmbedFooter.new text: '夏羽ボット：リリース 0.2 | 2021-03-27'
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new url: 'https://cdn.discordapp.com/attachments/811517007446671391/812998597628133386/1024px-Ruby_logo.png'
    embed.colour = 0x7C1A31
    embed.title = ''
    embed.fields = []
  end
end

client.command(:owoify, help_available: true, description: '夏羽に頼んで、入力したメッセージを赤ちゃんみたいな言葉を変えます。', 
                        usage: "#{ENV['PREFIX']}owoify <テキスト>",
                        min_args: 1,
                        arg_types: [String]) do |event|
  command_length = "#{ENV['PREFIX']}owoify".length + 1
  content = event.content[command_length..]
  event.respond(Owoify.owoify(content, 'uwu'))
end

client.run
