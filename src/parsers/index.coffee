# Import all known parsers in a convenient map.

asDriver = (parser) ->
  (raw) ->
    trimmed = raw.replace(/\u200B/g, "")
    "\n" + parser(trimmed.split(/\n/)).join("\n") + "\n"

exports.identity = asDriver require './identity'
exports.slackapp = asDriver require './slackapp'
