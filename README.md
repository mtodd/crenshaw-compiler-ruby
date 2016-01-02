# Let's Build a Compiler

This repository is my attempt to follow along the tutorial from 1988 by Jack Crenshaw called [*Let's Build a Compiler*][lbac].

[lbac]: http://compilers.iecc.com/crenshaw/

I've attempted to port both the Turbo Pascal sources from the tutorial to Ruby and the generated 68k assembler to x86-64 OS X assembler (my target host). See **Assembly** below for more details.

I've followed the original source and style pretty closely. I imagine at some point it will be fun to rewrite in a style I'm more familiar with, but that comes later.

## `cradle.rb`

This is the *cradle* program source that Crenshaw uses as a starting point.

I've modified it a bit to include some basic plumbing, primarily around the assembly bits.

## Assembly

The assembly produced targets my x86-64 OS X host.

I've attempted to interpret and translate the 68k assembly as best as I can, but I don't have a 68k host to test against and my assembler is *very* rusty (last time I played with assembly was on an emulated Z80 processor).

My goal is to produce a runnable program, even if some of the steps don't make perfect sense. This includes stubbing out some values because the tutorial isn't precisely clear about the expected outcomes.

## Sources

* http://compilers.iecc.com/crenshaw/
* ...and more.
