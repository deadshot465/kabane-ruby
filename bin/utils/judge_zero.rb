# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require_relative '../utils/util'

RUBY_LANG_ID = 72

module JudgeZero
  class << self
    def generate_auth_header(host)
      api_key = ENV['RAPID_API_KEY']
      {
        'content-type': 'application/json',
        'x-rapidapi-key': api_key,
        'x-rapidapi-host': host
      }
    end

    def try_get_eval_result(http, header, token, max_attempts)
      result = get_eval_result(http, header, token)
      max_attempts.times do
        break unless result[:response].nil?

        result = get_eval_result(http, header, token)
      end
      result
    end

    def build_embed(response, event)
      output = Base64.decode64(response['stdout']).force_encoding('utf-8')
      description = "これは**#{event.author.display_name.force_encoding('utf-8')}**が教えてくれたコードの解釈結果です。\n```bash\n#{output}\n```"
      description = description[0..2000] if description.length > 2000
      event.channel.send_embed do |embed|
        embed.author = Discordrb::Webhooks::EmbedAuthor.new
        embed.author.name = event.author.display_name
        embed.author.icon_url = event.author.avatar_url
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new url: RUBY_LOGO
        embed.colour = KABANE_COLOR
        embed.description = description
        embed.title = ''
        embed.fields = [
          Discordrb::Webhooks::EmbedField.new(name: '費やす時間', value: "#{response['time']} 秒", inline: true),
          Discordrb::Webhooks::EmbedField.new(name: 'メモリー', value: "#{response['memory']} KB",
                                              inline: true)
        ]

        if response['exit_code'].to_s != ''
          embed.fields << Discordrb::Webhooks::EmbedField.new(name: 'エグジットコード',
                                                              value: response['exit_code'].to_s,
                                                              inline: true)
        end

        if response['exit_signal'].to_s != ''
          embed.fields << Discordrb::Webhooks::EmbedField.new(name: 'エグジットシグナル',
                                                              value: response['exit_signal'].to_s,
                                                              inline: true)
        end
      end
    end

    private

    def get_eval_result(http, header, token)
      result_uri = URI.parse(RESULT_RAW_URL.gsub('{token}', token))
      response = http.request(Net::HTTP::Get.new(result_uri, header))
      puts "#{response.code}: #{response.message}"
      response_body = JSON.parse(response.body)
      handle_error_result = handle_error(response_body)
      if handle_error_result[:error_occurred]
        return {
          status: :failed,
          response: handle_error_result[:response]
        }
      end

      if handle_error_result[:response].nil?
        return {
          status: :in_progress,
          response: nil
        }
      end

      response = handle_error_result[:response]
      if response['stdout'].nil? && !response['compile_output'].nil?
        response['compile_output'] = Base64.decode64(response['compile_output']).force_encoding('utf-8')
        {
          status: :failed,
          response: response
        }
      elsif response['stdout'].nil? && response['compile_output'].nil?
        {
          status: :in_progress,
          response: nil
        }
      else
        {
          status: :succeeded,
          response: response
        }
      end
    end

    def handle_error(response)
      error_occurred = false

      if !response['stderr'].nil? && response['stderr'] != ''
        error_occurred = true
        response['stderr'] = Base64.decode64(response['stderr'])
      end

      if !response['message'].nil? && response['message'] != ''
        error_occurred = true
        response['message'] = Base64.decode64(response['message'])
      end

      {
        error_occurred: error_occurred,
        response: response
      }
    end
  end
end
