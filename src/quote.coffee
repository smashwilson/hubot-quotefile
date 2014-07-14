# Description:
#   Retrieve embarassing quotes from your co-workers out of context!
#
# Dependencies:
#   underscore, moment.js
#
# Configuration:
#   HUBOT_QUOTEFILE_PATH The location of the quotefile.
#
# Commands:
#   hubot quote - Retrieve a random quote.
#   hubot quote <query> - Retrieve a random quote that contains each word of <query>.
#   hubot howmany <query> - Return the number of quotes that contain each word of <query>.
#   hubot reload quotes - Reload the quote file.
#
# Author:
#   smashwilson

fs = require 'fs'
_ = require 'underscore'
moment = require 'moment'

CREATOR_ROLE = 'quote pontiff'

module.exports = (robot) ->

  # Global state.
  quotes = null

  # Read configuration from the environment.
  quotefilePath = process.env.HUBOT_QUOTEFILE_PATH

  reloadThen = (callback) ->
    unless quotefilePath?
      quotes = []
      return

    fs.readFile quotefilePath, encoding: 'utf-8', (err, data) ->
      if err?
        callback(err)
        return

      quotes = data.split /\n\n/
      quotes = _.filter quotes, (quote) -> quote.length > 1
      callback(null)

  isLoaded = (msg) ->
    if quotes?
      true
    else
      msg.reply "Just a moment, the quotes aren't loaded yet."
      false

  queryFrom = (msg) ->
    words = msg.match[1].trim().split /\s+/
    _.filter words, (part) -> part.length > 0

  quotesMatching = (query) ->
    if query.length > 0
      _.filter quotes, (quote) ->
        _.every query, (q) -> quote.indexOf(q) isnt -1
    else
      quotes

  # Perform the initial load.
  reloadThen ->

  robot.respond /quote(.*)/i, (msg) ->
    return unless isLoaded(msg)

    potential = quotesMatching queryFrom msg

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential[chosen]
    else
      msg.send "That wasn't notable enough to quote. Try harder."

  robot.respond /howmany(.*)/i, (msg) ->
    return unless isLoaded(msg)

    matches = quotesMatching queryFrom msg

    qstr = msg.match[1] or ' everything'
    msg.reply "There are #{matches.length} quotes about#{qstr}."

  robot.respond /reload quotes$/i, (msg) ->
    reloadThen (err) ->
      if err?
        msg.send "Oh, snap! Something blew up."
        msg.send err.stack
      else
        msg.send "#{quotes.length} quotes loaded successfully."

  robot.respond /create quote: ([\s\S]*)/i, (msg) ->
    unless robot.auth.hasRole(msg.message.user, CREATOR_ROLE)
      msg.reply [
        "You can't do that! You're not a *#{CREATOR_ROLE}*."
        "Ask an admin to run `#{robot.name} #{msg.message.user.name} has #{CREATOR_ROLE} role`."
      ].join("\n")
      return

    q = msg.match[1]

    # Post-processing specific to Slack.
    processed = ['']
    [speaker, ts] = []
    for line in q.split(/\n/)
      m = line.match /(\S+) \[(\d?\d):(\d\d) ([AP]M)\]/
      if m?
        [x, speaker, hours, minutes, ampm] = m
        hours += 12 if ampm is 'PM'
        timestamp = moment {hours: hours, minutes: minutes}
        ts = timestamp.format('h:mm A d MMM YYYY')
      else if speaker?
        processed.push "[#{ts}] #{speaker}: #{line}"
      else
        processed.push line
    processed.push ''

    nquote = processed.join("\n")
    fs.appendFile quotefilePath, nquote, ->
      msg.reply "Quote added."
      reloadThen (err) ->
        if err?
          msg.reply "AAAAAAAH"
          msg.send err.stack
        else
          msg.send "#{quotes.length} quotes reloaded successfully."
