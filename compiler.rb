#!/usr/bin/env ruby

ADDOPS = %w(+ -)

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
$label_count = 0
$stackdepth = 0

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

# Internal: Recognize an alphanumeric character.
#
# Returns true if the string character is an alpha or digit.
def is_alnum(c)
  is_alpha(c) || is_digit(c)
end

# Internal: Recognize a Decimal Digit
#
# Returns true if the string character is a digit.
def is_digit(c)
  c =~ /[0-9]/
end

# Internal: Recognize addition/subtraction operators.
#
# Return true if the string character is an addop.
def is_addop(c)
  ADDOPS.include?(c)
end

# Internal: Get an Identifier, and looks up the next character.
#
# Returns the alpha character String (prefixed with an underscore `_`).
def get_name
  la = $lookahead

  return expected("Name") unless is_alpha(la)

  lookahead

  "_#{la}"
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

def emit_section(section, out: $output)
  case section
  when :data
    out.print(".section __DATA,__data")
  when :text
    out.print(".section __TEXT,__text")
  else
    expected ":data, :text section"
  end
  out.puts
end

def comment(s, out: $output)
  emit("# #{s}", out: out)
  out.puts
end

def next_label
  label = "_l#{$label_count}"
  $label_count += 1
  label
end

def emit_label(label, out: $output)
  out.puts "#{label}:"
end

# FIXME: figure out a better way to define variables when needed, see if we can
# define the label/symbol without setting a default value, and maybe validate
# that they've been assigned before being used in the first place.
def define_variable(name)
  emit_section :data
  emit "#{name}: .long 0x0\n"
  emit_section :text
end

def alloc_stack
  $stackdepth += 1

  comment "make space for 8byte (64bit) value at #{$stackdepth}"
  emitln "subq $0x8, %rsp"
end

def free_stack
  comment "free space for 8byte (64bit) value at #{$stackdepth}"
  emitln "addq $0x8, %rsp"

  $stackdepth -= 1
end

def assembler_header(out: $output)
  out.puts HEADER
end

def assembler_footer(out: $output)
  out.puts
  out.puts FOOTER
end

def other
  name = get_name
  define_variable name
  emitln "movl #{name}(%rip), %eax"
end

# Recognize and Translate an IF Construct
#
#   IF <condition> <block> [ ELSE <block>] ENDIF
#
# becomes
#
#   IF
#   <condition>    { L1 = NewLabel;
#                    L2 = NewLabel;
#                    Emit(BEQ L1) }
#   <block>
#   ELSE           { Emit(BRA L2);
#                    PostLabel(L1) }
#   <block>
#   ENDIF          { PostLabel(L2) }
def if_statement
  match "i"
  condition

  if_label = next_label
  end_label = if_label

  emitln "je #{if_label}"
  block_statement

  if $lookahead == "l"
    match "l"
    end_label = next_label
    emitln "jmp #{end_label}"
    emit_label if_label
    block_statement
  end

  match "e"
  emit_label end_label
end

def condition
  emitln "cmpl $0x0, %eax"
end

# Recognize and Translate a Statement Block
def block_statement
  until $lookahead == "e"
    case $lookahead
    when "i"
      if_statement
    else
      other
    end
  end
end

#   <program> ::= <block> END
#   <block> ::= [ <statement> ]*
def program
  block_statement
  return expected("End") unless $lookahead == "e"
  comment "END" # 68k has an "END" instruction
end

def init
  alloc_stack
  lookahead
end

def main
  assembler_header

  init

  program

  assembler_footer

  debug_dump if ENV.key?('DEBUG')
end

def debug_dump
  STDERR.puts [:lookahead, $lookahead].inspect
end

if $0 == __FILE__
  main
end
