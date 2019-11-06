## OSIRIS
## This is an process watchdog.
## When the application has crashed
## it writes an crashdump and restarts the 
## watched program
## 
## Usage:
##  ./osiris myprogram -myparam --myparam2
import os, osproc, streams, times, strutils

const MAX_CHRS = 10_000       ## the len of the char ring buffer
const RESTART_TIMEOUT = 1_000 ## how long to wait between restarts

var 
  chrs: seq[char] = @[] ## character ringbuffer
  program = ""
  params: seq[string] = @[]

if paramCount() > 0:
  program = paramStr(1)
  if paramCount() > 1:
    for idx in 2..paramCount():
      params.add(paramStr(idx))

proc dump(): string = 
  let timestamp = $getTime()
  result = "crash_$1_$2__$3.txt" % [program.replace("/","_"), params.join("_") ,timestamp]
  var fs = newFileStream(result, fmWrite)
  for ch in chrs:
    fs.write(ch)
  return result

var ch: char
while true:
  var pr = startProcess(program, args = params)
  var ostr = pr.outputStream()
  while (not ostr.atEnd()) or pr.running():
    ch = ostr.readChar()
    chrs.add ch
    if chrs.len() > MAX_CHRS:
      chrs.delete(0) # delete oldes ringbuffer char
    write stdout, ch

  echo ""
  echo "----->"
  echo "-----> OSIRIS: application '$1 $2' died! Restarting!" % [program, params.join(" ") ]
  echo "----->"
  echo "dumping to:", dump()
  chrs.setLen(0) # clear the ring buffer for the next run
  sleep(RESTART_TIMEOUT)

