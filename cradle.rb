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
\t# exit with the result as %eax
\tmovl %eax, %edi       # set the exit code into %edi
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

# <factor> ::= (<expression>)
def factor
  if $lookahead == '('
    match "("
    expression
    match ")"
  else
    num = get_num
    comment num
    emitln "movl $#{num}, %eax"
  end
end

def multiply
  match "*"
  comment "*"
  factor
  emitln "imul %esp, %eax"
end

# Internal: Divide the dividend on the stack with the divisor in %eax.
#
# > Division requires special arrangements
# source: https://www.lri.fr/~filliatr/ens/compil/x86-64.pdf
#
# Division requires the divisor to be in %eax *and* %edx. Since we're only
# worried about 32bit values (right now), we put our 32bit value on the stack
# (%esp) into %eax and use cltd to convert the long into a double long. But
# first we move the divisor into %ebx because it's available and we need to
# make %eax available for the dividend.
def divide
  match "/"
  comment "/"
  factor
  emitln "movl %eax, %ebx"
  emitln "movl %esp, %eax"
  emitln "cltd"
  emitln "idivl %ebx"
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
  out.puts
end

def assembler_footer(out: $output)
  comment "return current sum as exit code"
  out.puts
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
