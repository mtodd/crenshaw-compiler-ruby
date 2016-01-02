# Part 1-3

Produces x86-64 assembly targeting OS X.

`make` expects the source from STDIN (see **Examples** below).

Sets the result of the expression to the exit code, so `make` will return an error during the `compile` step (for non-zero expressions).

Set `DEBUG=1` to dump debugging information (the lookahead character). This could be more useful.

## Examples

```
$ echo "a=1+2" | make
$ echo "b=(1+2)*3" | make
$ echo "c=((2+2)*3)/2" | make
$ echo "a=1" | DEBUG=1 make
```
