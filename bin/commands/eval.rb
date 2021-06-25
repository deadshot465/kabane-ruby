# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require_relative '../utils/judge_zero'

SUBMISSION_URL = URI.parse('https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=true&fields=*').freeze
RESULT_RAW_URL = 'https://judge0-ce.p.rapidapi.com/submissions/{token}?base64_encoded=true&fields=*'
MAX_ATTEMPTS = 10

module Commands
  class << self
    def eval(client)
      client.command(:eval, help_available: true, description: 'Rubyコードを解釈します。',
                            usage: "#{ENV['PREFIX']}eval <Rubyコード>",
                            min_args: 1,
                            arg_types: [String]) do |event|
        header = JudgeZero.generate_auth_header('judge0-ce.p.rapidapi.com')
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

        result = JudgeZero.try_get_eval_result(http, header, token, MAX_ATTEMPTS)
        status = result[:status]
        response = result[:response]
        case status
        when :failed
          msg = "何かおかしいことが発生しました。ミハイさんに確認してもらった方が良さそうだ。\n"
          msg += "これはエラーのメッセージ：#{response['stderr']}\n" if response['stderr'] != ''
          msg += "これは他のメッセージらしいです：#{response['message']}\n" if response['message'] != ''
          if !response['compile_output'].nil? && response['compile_output'] != ''
            msg += "なんか俺がこれをコンパイルできなさそうだ：#{response['compile_output']}\n"
          end
          msg = msg[0..2000] if msg.length > 2000
          event.respond(msg)
        when :in_progress
          event.respond('すみません。俺が何回も試してみたけど結果を出せなかったです。')
        when :succeeded
          JudgeZero.build_embed(response, event)
        else
          break
        end
      end
    end
  end
end
