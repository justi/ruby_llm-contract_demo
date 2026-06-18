# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v2_proposed"

q = Kb.golden_questions[4]
puts "Q: #{q}"
puts ""

result = FaqStepV2Proposed.run(q)
if result.ok?
  puts result.parsed_output[:answer]
else
  puts "status: #{result.status}"
  puts "parsed_output: #{result.parsed_output.inspect}"
  puts "raw (if any): #{result.raw_output}"
end
