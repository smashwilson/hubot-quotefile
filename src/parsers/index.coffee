# Import all known parsers in a convenient map.

asDriver = (parser) ->
  (raw) -> parser(raw.split(/\n/)).join("\n")

exports.identity = asDriver require './identity'
exports.slackClient = asDriver require './slackapp'
