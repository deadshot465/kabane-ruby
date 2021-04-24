# frozen_string_literal: true

require 'json'
require 'net/http'
require 'openssl'
require 'uri'
require_relative '../utils/rapid_api'
require_relative '../utils/util'

SUBMISSION_URL = URI.parse('https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=true&fields=*').freeze
RESULT_RAW_URL = 'https://judge0-ce.p.rapidapi.com/submissions/{token}?base64_encoded=true&fields=*'

module Commands
  class << self
    def eval(client)
      client.command(:eval, help_available: true, description: 'Rubyコードを解釈します。',
                            usage: "#{ENV['PREFIX']}eval <Rubyコード>",
                            min_args: 1,
                            arg_types: [String]) do |event|
        header = RapidAPI.generate_auth_header('judge0-ce.p.rapidapi.com')
        http = Net::HTTP.new(SUBMISSION_URL.host, SUBMISSION_URL.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        command_length = "#{ENV['PREFIX']}eval ".length
        request = Net::HTTP::Post.new(SUBMISSION_URL, header)
        code = event.content[command_length..].split(/\n/)
        actual_code = code[1..(code.length - 2)].join('; ')

        request.body = {
          language_id: RUBY_LANG_ID,
          source_code: Base64.strict_encode64(actual_code)
        }.to_json

        response = http.request(request)
        puts "#{response.code}: #{response.message}"
        token = JSON.parse(response.body)['token']
        loop do
          next unless get_eval_result?(http, header, token, event)

          break
        end
      end
    end

    private

    def get_eval_result?(http, header, token, event)
      result_uri = URI.parse(RESULT_RAW_URL.gsub('{token}', token))
      response = http.request(Net::HTTP::Get.new(result_uri, header))
      puts "#{response.code}: #{response.message}"
      response_body = JSON.parse(response.body)
      if !response_body['stderr'].nil? && response_body['stderr'] != ''
        stderr = Base64.decode64(response_body['stderr'])
        event.respond("何かおかしいことが発生しました。ミハイさんに確認してもらった方が良さそうだ：#{stderr}")
        if !response_body['message'].nil? && response_body['message'] != ''
          message = Base64.decode64(response_body['message'])
          event.respond("ちなみにこれは他のメッセージらしいです：#{message}")
        end
        return true
      end

      return false if response.nil? || response_body['stdout'].nil? || response_body['stdout'] == ''

      result = Base64.decode64(response_body['stdout']).force_encoding('utf-8')
      description = "これは**#{event.author.display_name.force_encoding('utf-8')}**が教えてくれたコードの解釈結果です。\n```bash\n#{result}\n```"
      if description.length > 2047
        event.respond('ごめん。そのコードの解釈結果は長すぎて、Discordはそれを許しませんので、俺もどうしようもない。')
        return true
      end

      event.channel.send_embed do |embed|
        embed.author = Discordrb::Webhooks::EmbedAuthor.new
        embed.author.name = event.author.display_name
        embed.author.icon_url = event.author.avatar_url
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new url: RUBY_LOGO
        embed.colour = KABANE_COLOR
        embed.description = description
        embed.title = ''
        embed.fields = [
          Discordrb::Webhooks::EmbedField.new(name: '費やす時間', value: "#{response_body['time']} 秒", inline: true),
          Discordrb::Webhooks::EmbedField.new(name: 'メモリー', value: "#{response_body['memory']} KB",
                                              inline: true)
        ]

        if response_body['exit_code'].to_s != ''
          embed.fields << Discordrb::Webhooks::EmbedField.new(name: 'エグジットコード',
                                                              value: response_body['exit_code'].to_s,
                                                              inline: true)
        end

        if response_body['exit_signal'].to_s != ''
          embed.fields << Discordrb::Webhooks::EmbedField.new(name: 'エグジットシグナル',
                                                              value: response_body['exit_signal'].to_s,
                                                              inline: true)
        end
      end
      true
    end
  end
end
