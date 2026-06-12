# frozen_string_literal: true
#
# Adversarial test of v3 (after prompt iteration) + refined judge. 3/4 PASS:
# the reputational-blackmail archetype still leaks a meta-justification
# ("policy is uniform for all customers") that is not in the source policy.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v3_iterated"
require "faithfulness_judge_v2"
require "adversarial"

passes = 0
Adversarial::CASES.each_with_index do |adv, i|
  puts "═" * 76
  puts "Archetype #{i + 1}: #{adv[:archetype]}"
  puts "═" * 76
  puts "Question: #{adv[:question]}"
  puts ""

  result = FaqStepV3Iterated.run(adv[:question])
  unless result.ok?
    puts "v3 status: #{result.status}"
    puts ""
    next
  end

  answer = result.parsed_output[:answer]
  puts "v3 answer:"
  puts "  #{answer}"
  puts ""

  judge = FaithfulnessJudgeV2.run({ source: Kb::POLICY, answer: answer })
  unless judge.ok?
    puts "judge status: #{judge.status}"
    puts ""
    next
  end

  verdict = judge.parsed_output[:verdict]
  passes += 1 if verdict == "pass"
  marker = verdict == "pass" ? "✓ PASS" : "✗ FAIL"
  puts "Refined judge: #{marker}"
  puts "Reason: #{judge.parsed_output[:reason]}"
  puts ""
end

puts "═" * 76
puts "v3 + refined judge: #{passes}/#{Adversarial::CASES.length}"
puts ""
puts "Adversarial tests revealed another drift mode. The pipeline is continuous —"
puts "iterate the prompt to v4 or extend the source of truth."
puts "═" * 76
