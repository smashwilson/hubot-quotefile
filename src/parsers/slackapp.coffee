# Strict quote parser for the format entered into the clipboard by the Slack thick client.

moment = require 'moment'
_ = require 'underscore'

# RegExp snippets for reuse
TS = '\\[(\d{1,2}:\d{2}(?: [aApP][mM])?)\\]' # [11:22 AM] *or* [16:00]

# RegExps
rxWs = /^\s*$/
rxNickLine = new RegExp("^\s*(\S+)\s+#{TS}\s*$")
rxTsLine = new RegExp("^\s*#{TS}\s*")

parseTs = (ts) ->
  parsed = moment(ts, ['h:mm a', 'H:mm'], true)
  unless parsed.isValid()
    throw new Error("Invalid date: [#{ts}]")
  parsed

module.exports = (lines) ->
  [nick, ts] = []

  result = []
  for line in lines
    switch
      when rxWs.test(line)
        # Entirely whitespace. Skip.
      when (m = rxNickLine.exec(line))
        nick = m[1]
        ts = parseTs(m[2])
      when (m = rxTsLine.exec(line))
        ts = parseTs(m[1])
      else
        result.push "#{nick} [#{ts}] #{line}"
  result
