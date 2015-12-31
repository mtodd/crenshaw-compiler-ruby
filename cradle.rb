#!/usr/bin/env ruby

ADDOPS = %w(+ -)

TAB = "\t"

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

# Internal: Recognize addition/subtraction operators.
#
# Return true if the string character is an addop.
def is_addop(c)
  ADDOPS.include?(c)
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

def debug_dump
  p [:lookahead, $lookahead]
end

def main
  lookahead

  debug_dump if ENV.key?('DEBUG')
end

if $0 == __FILE__
  main
end
