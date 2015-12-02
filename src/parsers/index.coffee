# Import all known parsers in a convenient map.

asDriver = (parser) ->
  (raw) -> "\n" + parser(raw.split(/\n/)).join("\n") + "\n"

exports.identity = asDriver require './identity'
exports.slackapp = asDriver require './slackapp'
