require 'rspec'
require 'parslet/rig/rspec'
require './parser'

describe QADSLParser  do
  let(:parser) { QADSLParser.new }

  context "question_def" do

    it "should consume question" do
      expect(parser.question_def).to parse("Q: Are you hungry? [yes/no] => HUNGRY|FULL\n", {trace: true})
    end

    it "should consume question2" do
      expect(parser.question_def).to parse('Q: Are you feeling tired? [yes/no] => TIRED|AWAKE', {trace: true})
    end

    it "should consume question3" do
      expect(parser.question_def).to parse('Q: How many Devs do you have? [<10/<20/>=20] => SMALL_TEAM|MID_TEAM|BIG_TEAM ', {trace: true})
    end
  end

  context "rule_def" do
    it "should consume ruledef1" do
      expect(parser.rule_def).to parse("{FULL} Don't eat anything!", {trace: true})
    end

    it "should consume ruledef2" do
      expect(parser.rule_def).to parse("{HUNGRY & TIRED & HAVE_LOLLIES} Eat Lollies! \n", {trace: true})
    end
  end

  context "doc" do
    it "should consume questions" do
      expect(parser.doc).to parse(
"""Q: Are you hungry? [yes/no] => HUNGRY|FULL
Q: Are you hungry? [yes/no] => HUNGRY|FULL""" , {trace: true}
      )
    end

  end

end

RSpec::Core::Runner.run([])
