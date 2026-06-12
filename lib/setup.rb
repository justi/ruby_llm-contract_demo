# frozen_string_literal: true

# Shared boot: load .env, validate API key, gate on LIVE=1, configure RubyLLM.
# Every script: `require "setup"`.
#
# Demo hits real OpenAI API. Set `LIVE=1` to explicitly confirm you want
# to spend ~$0.01-0.03 per script (~$0.30 for full lifecycle).

require "ruby_llm/contract"

# Load .env if present (project root).
env_path = File.expand_path("../../.env", __FILE__)
if File.exist?(env_path)
  File.readlines(env_path).each do |line|
    line.strip!
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    ENV[key] ||= value
  end
end

# LIVE=1 guard — protects adopter from surprise billing.
unless ENV["LIVE"] == "1"
  warn <<~MSG

    ⚠️  This demo makes real OpenAI API calls (`gpt-4.1-mini`).
        Estimated cost:
          - per script:       ~$0.01-0.03
          - full lifecycle:   ~$0.20-0.30 (scripts 01-10)

        To run:
          LIVE=1 OPENAI_API_KEY=sk-... bundle exec ruby #{$PROGRAM_NAME}

        Or: cp .env.example .env, add key, then:
          LIVE=1 bundle exec ruby #{$PROGRAM_NAME}

  MSG
  exit 1
end

# API key check with helpful message instead of bare KeyError.
api_key = ENV["OPENAI_API_KEY"]
if api_key.nil? || api_key.strip.empty?
  warn <<~MSG

    ❌ OPENAI_API_KEY is not set.

        Option 1:  OPENAI_API_KEY=sk-... LIVE=1 bundle exec ruby #{$PROGRAM_NAME}
        Option 2:  cp .env.example .env, add the key, then `LIVE=1 bundle exec ...`

        Get a key at https://platform.openai.com/api-keys.

  MSG
  exit 1
end

RubyLLM.configure { |c| c.openai_api_key = api_key }
RubyLLM::Contract.configure {}
