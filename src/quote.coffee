# Description:
#   Retrieve embarassing quotes from your co-workers out of context!
#
# Dependencies:
#   underscore
#
# Configuration:
#   HUBOT_QUOTEFILE_PATH The location of the quotefile.
#
# Commands:
#   hubot quote - Retrieve a random quote.
#   hubot quote <query> - Retrieve a random quote that contains each word of <query>.
#   hubot reload quotes - Reload the quote file.
#
# Author:
#   smashwilson

fs = require 'fs'
_ = require 'underscore'

module.exports = (robot) ->

  # Global state.
  quotes = []

  # Read configuration from the environment.
  quotefilePath = process.env.HUBOT_QUOTEFILE_PATH
  unless quotefilePath?
    throw new Error('hubot-quotefile: HUBOT_QUOTEFILE_PATH must be specified.')

  reloadThen = (callback) ->
    fs.readFile quotefilePath, encoding: 'utf-8', (err, data) ->
      if err?
        callback(err)
        return

      quotes = data.split /\n\n/
      quotes = _.filter quotes, (quote) -> quote.length > 1
      callback(null)

  rxEscape = (str) -> (str + '').replace /([.?*+^$[\]\\(){}|-])/g, "\\$1"

  robot.respond /quote(.*)/i, (msg) ->
    query = msg.match[1].trim().split /\s+/
    query = _.filter query, (part) -> part.length > 0

    potential = quotes

    if query.length > 0
      escaped = (rxEscape(q) for q in query).join '|'
      pattern = new RegExp(escaped, "gi")
      potential = _.filter potential, (quote) -> pattern.test(quote)

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential[chosen]
    else
      msg.send "That wasn't notable enough to quote. Try harder."

  robot.respond /reload quotes$/i, (msg) ->
    reloadThen (err) ->
      if err?
        msg.send "Oh, snap! Something blew up."
        msg.send err.stack
      else
        msg.send "#{quotes.length} quotes loaded successfully."
