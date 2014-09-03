require 'rubygems'
require 'parslet'

class QADSLParser < Parslet::Parser
  root(:doc)
    rule(:doc) {
        (
            question_def    |
            rule_def        |
            blank_line      |
            comment_line
        ).repeat(1) >>
        sp? >> eof
    }

    rule(:question_def) {
        (
        str('Q:') >> sp? >>
        question >> sp? >>
        options_list >> sp? >>
        str("=>") >> sp? >>
        states_list >> sp? >>
        eol
        ).as(:question)
    }
    rule(:question)     { ((str("?").absent? >> any).repeat(1) >> str("?")).as(:question_text)}
    rule(:sp?)          { str(' ').repeat(0) }
    rule(:options_list) { (str("[") >> option >> (str("/") >> option).repeat(1)>> str("]")).as(:options) }
    rule(:option)       { ((str("]").absent? >> str("/").absent? >> any).repeat(1)).as(:option) }
    rule(:states_list)  { (state >> ( str("|") >> state).repeat(1)).as(:states) }
    rule(:state)        { (match['A-Z_'].repeat(1)).as(:state) }
    rule(:eol)          { (str("\r").maybe >> str("\n"))  | eof }
    rule(:eof)          { any.absent? }

    rule(:blank_line)   { str(" ").maybe >> str("\n") }

    rule(:comment_line) { str(':') >> (str("\n").absent? >> any ).repeat(1) >> eol }

    rule(:rule_def)     { (condition_expression >> conclusion).as(:rule_def)  >> eol }
    rule(:condition_expression) {
      str('{') >>
        (condition >> (and_op >> condition).repeat(0)).as(:conditions) >>
      str('}') >> sp?
    }
    rule(:condition) { state }
    rule(:and_op) { sp? >> str('&') >> sp? }
    rule(:conclusion) { (eol.absent? >> any).repeat(1).as(:result) }
end

class MyTransform < Parslet::Transform
  rule(state: simple(:name))  { builder.state(name) }
  rule(option: simple(:name)) { builder.option(name) }
  rule(
    question_text: simple(:text),
    options: sequence(:options),
    states: sequence(:states)
  ) { builder.question(text, options, states) }
  rule(question: simple(:questions)) { questions }
  rule(conditions: simple(:condition), result: simple(:result)){ 
      builder.rule([condition], result) 
  }
  rule(conditions: sequence(:conditions), result: simple(:result)){ 
      builder.rule(conditions, result) 
  }
  rule(rule_def: simple(:rule)){ rule }
end

class State
  def initialize(name)
    @name = name
  end
end

class Option
  def initialize(name)
    @name = name
  end
end

class Question
  def initialize(text, options, states)
    @text, @options, @states = text, options, states
  end
end

class Rule
  def initialize(conditions, result)
    @conditions = conditions
    @result = result
  end  
end

class Wizard
    def initialize(questions, rules)
        @questions, @rules = questions, rules
    end
    
    def run
        unasked = @questions.dup
        rules = @rules.dup
        # find possible outcomes
        # find question that splits outcomes
        # keep asking questions until an outcome is found        
    end
end

class Builder
  def initialize
    @states = {}
    @options = {}
    @questions = []
    @rules = []
  end

  def state(name)
    @states[name] ||= State.new(name)
  end

  def option(name)
    @options[name] ||= Option.new(name)
  end

  def question(text, options, states)
    x = Question.new(text, options, states)
    @questions << x
    nil
  end
  
  def rule(conditions, state)
    x = Rule.new(conditions, state)
    @rules << x
    nil
  end
  
  def wizard()
    Wizard.new(@questions, @rules)
  end
end

if __FILE__==$0
  require 'pp'

  file = File.read(ARGV[0])
  lines = file.split("\n")
  lines.each_with_index{|line,i| puts "#{i+1}: #{line}" }
  parser = QADSLParser.new
  trans = MyTransform.new
  begin
    builder = Builder.new
    pp trans.apply(parser.parse(file), builder: builder )
    puts "=============="
    pp wiz = builder.wizard
    puts "=============="
    wiz.run
  rescue Parslet::ParseFailed => error
    puts error.cause.ascii_tree
  end
end
