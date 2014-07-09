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
    fs.readFile quotefilePath, (err, data) ->
      if err?
        callback(err)
        return

      quotes = data.split /\n\n/
      callback(null)

  rxEscape = (str) -> (str + '').replace /([.?*+^$[\]\\(){}|-])/g, "\\$1"

  robot.respond /quote(.*)/, (msg) ->
    query = msg.match[2].trim().split /\W+/

    potential = quotes

    if query.length > 0
      pattern = new Regexp(rxEscape query.join '|')
      potential = _.filter potential, (quote) -> pattern.match quote

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential
    else
      msg.send "That wasn't notable enough to quote. Try harder."

  robot.respond /reload quotes$/, (msg) ->
    reloadThen (err) ->
      if err?
        msg.send "Oh, snap! Something blew up."
        msg.send err.stack
      else
        msg.send "#{quotes.length} loaded successfully."
