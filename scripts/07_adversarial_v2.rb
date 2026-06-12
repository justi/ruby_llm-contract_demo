# frozen_string_literal: true
#
# Adversarial test of v2 (PR 'be warm') + raw judge. v2 emits commitments
# outside the policy — the judge catches them, but its over-eagerness also
# blocks cases where the length validate already truncated the answer.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "setup"
require "kb"
require "faq_step_v2_proposed"
require "faithfulness_judge"
require "adversarial"

Adversarial.cases.each_with_index do |adv, i|
  puts "═" * 76
  puts "Archetype #{i + 1}: #{adv[:archetype]}"
  puts "═" * 76
  puts "Question: #{adv[:question]}"
  puts ""

  result = FaqStepV2Proposed.run(adv[:question])
  unless result.ok?
    puts "v2 status: #{result.status}, errors: #{result.validation_errors}"
    puts ""
    next
  end

  answer = result.parsed_output[:answer]
  puts "v2 answer:"
  puts "  #{answer}"
  puts ""

  judge = FaithfulnessJudge.run({ source: Kb.policy, answer: answer })
  unless judge.ok?
    puts "judge status: #{judge.status}"
    puts ""
    next
  end

  verdict = judge.parsed_output[:verdict]
  marker = verdict == "pass" ? "✓ PASS" : "✗ FAIL"
  puts "Raw judge: #{marker}"
  puts "Reason: #{judge.parsed_output[:reason]}" if verdict == "fail"
  puts ""
end

puts "Schema valid everywhere. No gate → production. With the gate → judge catches it."
