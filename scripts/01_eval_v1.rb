# frozen_string_literal: true
#
# v1 gate — production prompt + reference questions + refined judge.
# Expected score: 1.0 (every answer faithful to the policy).
#
# Run: LIVE=1 OPENAI_API_KEY=sk-... bundle exec ruby scripts/01_eval_v1.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "evals"

puts "Gate: FaqStep (v1) + refined judge + 5 reference questions"
puts ""

report = FaqStep.run_eval(EVAL_NAME)

report.results.each do |case_result|
  marker = case_result.passed? ? "✓" : "✗"
  ans = case_result.output.is_a?(Hash) ? case_result.output[:answer].to_s : case_result.output.to_s
  puts "  #{marker}  #{case_result.name.ljust(8)} score=#{case_result.score} | #{ans[0..80]}..."
end

puts ""
puts "Score: #{report.score}  Verdict: #{report.passed? ? 'PASS' : 'FAIL'}"
