#!/usr/bin/env ruby

ADDOPS = %w(+ -)
MULOPS = %w(* /)

TAB = "\t"

$srcin = ARGF
$input = STDIN
$output = STDOUT

$lookahead = nil
$var_table = Hash.new { |h,k| h[k] = 0 }

# Internal: Read a character from input stream
def lookahead(input: $srcin)
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

def match_newline
  lookahead while $lookahead == "\n"
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
  value = 0

  return expected("Integer") unless is_digit($lookahead)

  while is_digit($lookahead)
    value = 10 * value + $lookahead.to_i
    lookahead
  end

  value
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

def input(input: $input)
  match "?"
  $var_table[get_name] = input.readline.chomp
end

def output(out: $output)
  match "!"
  out.puts $var_table[get_name]
end

def factor
  case
  when $lookahead == "("
    match "("
    value = expression
    match ")"
    value
  when is_alpha($lookahead)
    $var_table[get_name]
  else
    get_num
  end
end

def term
  value = factor

  while MULOPS.include?($lookahead)
    case $lookahead
    when "*"
      match "*"
      value = value * factor
    when "/"
      match "/"
      value = value / factor
    end
  end

  value
end

def expression
  value =
    if is_addop($lookahead)
      0
    else
      term
    end

  while is_addop($lookahead)
    case $lookahead
    when "+"
      match "+"
      value += term
    when "-"
      match "-"
      value -= term
    end
  end

  value
end

def assignment
  name = get_name
  match "="
  $var_table[name] = expression
end

def init
  lookahead
end

def main
  init

  until $lookahead == "."
    case $lookahead
    when "?"
      input
    when "!"
      output
    else
      assignment
    end

    match_newline
  end

  debug_dump if ENV.key?('DEBUG')

  exit 0
end

def debug_dump
  STDERR.puts [:lookahead, $lookahead].inspect
  STDERR.puts [:var_table, $var_table].inspect
end

if $0 == __FILE__
  main
end
