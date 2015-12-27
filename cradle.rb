#!/usr/bin/env ruby

ADDOPS = %w(+ -)
MULOPS = %w(* /)

TAB = "\t"

HEADER = <<-ASM
.section __TEXT,__text
.global _main
_main:
ASM

FOOTER = <<-ASM
\tmovl %eax, %edi         # set the exit code to be whatever is %eax
\tmovl $0x2000001, %eax # system call $1 with $0x2000000 offset
\tsyscall
ASM

$input  = STDIN
$output = STDOUT

$lookahead = nil

# Internal: Read a character from input stream
def lookahead(input: $input)
  $lookahead = input.getc
end

# Inernal: Report an error.
def report_error(error, out: $output)
  out.puts
  out.puts "Error: #{error}."
end

# Inernal: Report an error and halt.
def abort(s)
  report_error(s)
  exit 1
end

# Internal: Report What Was Expected
def expected(s)
  abort "#{s} Expected"
end

# Internal : Match a Specific Input Character
def match(x)
  if $lookahead == x
    lookahead
  else
    expected x
  end
end

# Internal: Recognize an Alpha Character.
#
# Returns true if the string character is an alpha.
def is_alpha(c)
  c =~ /[a-z]/i
end

# Internal: Recognize a Decimal Digit
#
# Returns true if the string character is a digit.
def is_digit(c)
  c =~ /[0-9]/
end

# Internal: Get an Identifier, and looks up the next character.
#
# Returns the alpha character String (upcased).
def get_name
  la = $lookahead

  return expected("Name") unless is_alpha(la)

  lookahead

  la.upcase
end

# Internal: Get a Number
#
# Returns the digit character String.
def get_num
  la = $lookahead

  return expected("Integer") unless is_digit(la)

  lookahead

  la
end

# Internal: Output a String with Tab
def emit(s, out: $output)
  out.print(TAB, s)
end

# Internal: Output a String with Tab and CRLF
def emitln(s, out: $output)
   emit(s, out: out)
   out.puts
end

def comment(s, out: $output)
  emit("# #{s}", out: out)
  out.puts
end

def factor
  num = get_num
  comment num
  emitln "movl $#{num}, %eax"
end

def multiply
  match "*"
  factor
  emitln "imull %esp, %eax"
end

def divide
  match "/"
  factor
  emitln "movl %esp, %ebx"
  emitln "divl %ebx, %eax"
end

# Internal: Parse and Translate a Math Expression.
#
#   <term> ::= <factor>  [ <mulop> <factor> ]*
def term
  factor
  while MULOPS.include?($lookahead)
    emitln "movl %eax, %esp"
    case $lookahead
    when "*"
      multiply
    when "/"
      divide
    else
      expected "mulop"
    end
  end
end

# Internal: Recognize and Translate an Add
def add
  match "+"
  comment "+"
  term
  emitln "addl %esp, %eax"
end

# Internal: Recognize and Translate a Subtract
def subtract
  match "-"
  comment "-"
  term
  emitln "subl %esp, %eax"
  emitln "neg %eax"
end

# Internal: Parse and Translate an Expression
#
#   <expression> ::= <term> [<addop> <term>]*
def expression
  term
  while ADDOPS.include?($lookahead)
    emitln "movl %eax, %esp"
    case $lookahead
    when "+"
      add
    when "-"
      subtract
    else
      expected "Addop"
    end
  end
end

def assembler_header(out: $output)
  out.puts HEADER
end
def assembler_footer(out: $output)
  out.puts FOOTER
end

def main
  assembler_header

  lookahead
  expression

  assembler_footer

  debug_dump if ENV.key?('DEBUG')
end

def debug_dump
  STDERR.puts [:lookahead, $lookahead].inspect
end

if $0 == __FILE__
  main
end
