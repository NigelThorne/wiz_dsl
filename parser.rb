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
    rule(:conclusion) { (eol.absent? >> any).repeat(1) }
end

if __FILE__==$0
  file = File.read(ARGV[0])
  lines = file.split("\n")
  lines.each_with_index{|line,i| puts "#{i+1}: #{line}" }
  parser = QADSLParser.new
  begin
    puts parser.parse(file)
  rescue Parslet::ParseFailed => error
    puts error.cause.ascii_tree
  end
end
