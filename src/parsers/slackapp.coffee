# Strict quote parser for the format entered into the clipboard by the Slack thick client.

moment = require 'moment'
_ = require 'underscore'

# RegExp snippets for reuse
TS = '\\[(\d{1,2}:\d{2}( [aApP][mM])?)\\]' # [11:22 AM] *or* [16:00]

# RegExps
rxWs = /^\s*$/
rxNickLine = new RegExp("^\s*(\S+)\s+#{TS}\s*$")
rxTsLine = new RegExp("^\s*#{TS}\s*")
rxNewMessagesLine = new RegExp("^\snew messages*\s*$")

parseTs = (ts) ->
  parsed = moment(ts, ['h:mm a', 'H:mm'], true)
  unless parsed.isValid()
    throw new Error("Invalid date: [#{ts}]")
  parsed

module.exports = (lines) ->
  [nick, ts, ampm] = []

  result = []
  for line in lines
    if rxWs.test line
      continue

    if rxNewMessagesLine.test line
      continue

    m = rxNickLine.exec line
    if m?
      nick = m[1]
      ts = parseTs m[2]
      ampm = m[3]
      continue

    m = rxTsLine.exec line
    if m?
      rawTs = m[1]
      rawTs += ampm if ampm? and not m[2]?
      ts = parseTs rawTs
      continue

    unless nick? and ts?
      throw new Error("Expected nick and timestamp line first.")

    line = line.replace(/\s*\(edited\)$/, '')

    result.push "#{nick} [#{ts}] #{line}"
  result
