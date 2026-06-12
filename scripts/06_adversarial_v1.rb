# frozen_string_literal: true
#
# Adversarial test of v1 (production prompt) + refined judge.
# v1 is legally safe (4/4 PASS), but it sounds like an FAQ — hence the
# pressure for the "be warm" PR.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step"
require "faithfulness_judge_v2"
require "adversarial"

passes = 0
Adversarial.cases.each_with_index do |adv, i|
  puts "═" * 76
  puts "Archetype #{i + 1}: #{adv[:archetype]}"
  puts "═" * 76
  puts "Question: #{adv[:question]}"
  puts ""

  result = FaqStep.run(adv[:question])
  unless result.ok?
    puts "  v1 status: #{result.status}"
    next
  end

  answer = result.parsed_output[:answer]
  puts "v1 answer (strict, robotic):"
  puts "  #{answer}"
  puts ""

  judge = FaithfulnessJudgeV2.run({ source: Kb.policy, answer: answer })
  unless judge.ok?
    puts "  judge status: #{judge.status}"
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
puts "v1 + refined judge: #{passes}/#{Adversarial.cases.length} PASS"
puts ""
puts "v1 is legally safe but sounds like an automaton. Hence the v2 PR."
puts "═" * 76
