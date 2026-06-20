# frozen_string_literal: true
#
# Same 5 questions as in 02, but graded by the refined judge (which
# distinguishes stylistic courtesy from a commitment). Result varies run-to-run
# (~2-3 of 5 PASS at temperature 0) - signal vs noise.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v2_proposed"
require "faithfulness_judge_v2"

passes = 0
Kb.golden_questions.each_with_index do |question, idx|
  result = FaqStepV2Proposed.run(question)
  unless result.ok?
    puts "case_#{idx + 1}: FaqStep status #{result.status}"
    next
  end

  answer = result.parsed_output[:answer]
  judge = FaithfulnessJudgeV2.run({ source: Kb.policy, answer: answer })
  unless judge.ok?
    puts "case_#{idx + 1}: judge status #{judge.status}"
    next
  end

  verdict = judge.parsed_output[:verdict]
  passes += 1 if verdict == "pass"
  marker = verdict == "pass" ? "✓" : "✗"

  puts "case_#{idx + 1}: #{marker} #{verdict.upcase}"
  puts "  answer: #{answer[0..120]}#{answer.length > 120 ? '...' : ''}"
  puts "  reason: #{judge.parsed_output[:reason]}" if verdict == "fail"
  puts ""
end

puts "Refined judge on v2: #{passes}/#{Kb.golden_questions.length}"
