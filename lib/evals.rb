# frozen_string_literal: true

require_relative "kb"
require_relative "faq_step"
require_relative "faq_step_v2_proposed"
require_relative "faithfulness_judge_v2"

# Production gate. Iterates the reference questions and uses the refined
# judge as the evaluator. CI gate requires score >= 0.9.
EVAL_NAME = "faithfulness"

# Defensive evaluator: if the judge step itself fails (parse error, cost limit),
# treat the case as 0.0 — never trust a partial `parsed_output`.
# The judge's own status is the source of truth.
def install_faithfulness_eval(klass)
  klass.define_eval(EVAL_NAME) do
    Kb.golden_questions.each_with_index do |question, i|
      add_case "case_#{i + 1}",
               input: question,
               evaluator: ->(output, _input) {
                 verdict = FaithfulnessJudgeV2.run(
                   { source: Kb.policy, answer: output[:answer] }
                 )
                 next 0.0 unless verdict.ok?

                 verdict.parsed_output[:verdict] == "pass" ? 1.0 : 0.0
               }
    end
  end
end

install_faithfulness_eval(FaqStep)
install_faithfulness_eval(FaqStepV2Proposed)
