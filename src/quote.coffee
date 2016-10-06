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
#   hubot quoteby <username> [<query>] - Retrieve a random quote including a line spoken by <username>.
#   hubot quoteabout <username> [<query>] - Retrieve a random quote including a line addressing <username>.
#   hubot howmany <query> - Return the number of quotes that contain each word of <query>.
#   hubot reload quotes - Reload the quote file.
#   hubot quotestats - Show who's been quoted the most!
#   hubot verbatim quote: [...] - Enter a quote into the quote file exactly as given.
#   hubot slackapp quote: [...] - Parse a quote from the Slack app's paste format.
#   hubot buffer quote - Enter a quote from the buffer.
#
# Author:
#   smashwilson

fs = require 'fs'
_ = require 'underscore'
moment = require 'moment'
parsers = require './parsers'

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

  queryFrom = (msg, matchNumber = 1) ->
    if msg.match[matchNumber]?
      words = msg.match[matchNumber].trim().split /\s+/
    else
      words = ['']
    _.filter words, (part) -> part.length > 0

  quotesMatching = (query = [], speakers = [], mentions = []) ->
    results = quotes

    if speakers.length > 0 or mentions.length > 0
      results = _.filter results, (quote) ->
        speakersNotSeen = new Set(speakers)
        mentionsNotSeen = new Set(mentions)

        for line in quote.split /\n/
          m = line.match /^\[[^\]]+\] @?([^:]+): (.*)$/
          if m?
            [x, speaker, rest] = m
            speakersNotSeen.delete(speaker)
            for mention in mentions
              mentionsNotSeen.delete(mention) if rest.includes mention

        speakersNotSeen.size is 0 and mentionsNotSeen.size is 0

    if query.length > 0
      rxs = (new RegExp(q, 'i') for q in query)
      results = _.filter results, (quote) ->
        _.every rxs, (rx) -> rx.test(quote)

      results

    results

  # Perform the initial load.
  reloadThen ->

  robot.respond /quote(\s.*)?$/i, (msg) ->
    return unless isLoaded(msg)

    potential = quotesMatching queryFrom msg

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential[chosen]
    else
      msg.send "That wasn't notable enough to quote. Try harder."

  robot.respond /quoteby\s+@?(\S+)(\s+.*)?$/i, (msg) ->
    return unless isLoaded(msg)

    speakers = msg.match[1].split('+')
    query = queryFrom msg, 2

    potential = quotesMatching query, speakers, null

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential[chosen]
    else
      m = "No quotes with lines spoken by "

      if speakers.length is 1
        m += speakers[0]
      else if speakers.length is 2
        m += "both #{speakers[0]} and #{speakers[1]}"
      else
        m += "all of #{speakers.join ', '}"

      if query.length > 0
        m += " about that"

      msg.send m + '.'

  robot.respond /quoteabout\s+@?(\S+)(\s+.*)?$/i, (msg) ->
    return unless isLoaded(msg)

    mentions = msg.match[1].split('+')
    query = queryFrom msg, 2

    potential = quotesMatching query, null, mentions

    if potential.length > 0
      chosen = _.random potential.length - 1
      msg.send potential[chosen]
    else
      m = "No quotes about "

      if mentions.length is 1
        m += mentions[0]
      else if mentions.length is 2
        m += "both #{mentions[0]} and #{mentions[1]}"
      else
        m += "all of #{mentions.join ', '}"

      if query.length > 0
        m += " about that"

      msg.send m + '.'

  robot.respond /howmany(\s.*)/i, (msg) ->
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

  robot.respond /(verbatim|slackapp) quote:\s*([^]+)/i, (msg) ->
    unless robot.auth.hasRole(msg.message.user, CREATOR_ROLE)
      msg.reply [
        "You can't do that! You're not a *#{CREATOR_ROLE}*."
        "Ask an admin to run `#{robot.name} #{msg.message.user.name} has #{CREATOR_ROLE} role`."
      ].join("\n")
      return

    pname = msg.match[1]
    pname = 'identity' if pname is 'verbatim'

    parse = parsers[pname]
    unless parse?
      msg.reply [
        "I don't recognize the `#{pname}` parser."
        "Please file an issue at: https://github.com/smashwilson/hubot-quotefile/issues/new"
      ].join("\n")
      return

    try
      quote = parse msg.match[2]
    catch e
      msg.reply [
        "http://www.sadtrombone.com/"
        e.message
        "```\n#{e.stack}\n```"
      ].join("\n")
      return

    fs.appendFile quotefilePath, quote, ->
      msg.reply "Quote added."
      reloadThen (err) ->
        if err?
          msg.reply "AAAAAAAH"
          msg.send err.stack
        else
          msg.send "#{quotes.length} quotes reloaded successfully."

  robot.respond /buffer quote/i, (msg) ->
    unless robot.auth.hasRole(msg.message.user, CREATOR_ROLE)
      msg.reply [
        "You can't do that! You're not a *#{CREATOR_ROLE}*."
        "Ask an admin to run `#{robot.name} #{msg.message.user.name} has #{CREATOR_ROLE} role`."
      ].join("\n")
      return

    unless robot.bufferForUserName?
      msg.reply "Buffer package not available."
      return

    buffer = robot.bufferForUserName msg.message.user.name
    lines = buffer.commit()

    unless lines.length > 0
      msg.reply "Your buffer is empty."
      return

    processed = for line in lines
      if line.isRaw()
        line.text
      else
        ts = moment(line.timestamp).format('h:mm A D MMM YYYY')
        "[#{ts}] #{line.speaker}: #{line.text}"
    quote = processed.join("\n")

    msg.send quote

    quote = "\n" + quote + "\n"

    fs.appendFile quotefilePath, quote, ->
      msg.reply "Quote added."
      reloadThen (err) ->
        if err?
          msg.reply "AAAAAAAH"
          msg.send err.stack
        else
          msg.send "#{quotes.length} quotes reloaded successfully."

  robot.respond /quotestats$/i, (msg) ->
    return unless isLoaded(msg)

    usernames = []
    for uid in Object.keys(robot.brain.users())
      usernames.push robot.brain.users()[uid].name
    if usernames.length is 0
      msg.reply "I have no users. How can that be?"
      return

    results = {}

    incrementResultFor = (username, kind) ->
      r = results[username] ?=
        spoke: 0
        mentioned: 0
      r[kind] += 1

    for quote in quotes
      [speakers, mentioned] = [[], []]
      mentionMatcher = new RegExp(usernames.join('|'), 'g')
      mentionsFrom = (str) ->
        mention = mentionMatcher.exec(str)
        mentioned.push mention[0] if mention?
        while mention?
          mention = mentionMatcher.exec(str)
          mentioned.push mention[0] if mention?

      for line in quote.split(/\n/)
        m = line.match(/^\[[^\]]+\] @?([^:]+): (.*)$/)
        if m?
          [x, speaker, rest] = m
          speakers.push speaker
          mentionsFrom(rest)
        else
          mentionsFrom(line)

      incrementResultFor(u, 'spoke') for u in _.uniq speakers
      incrementResultFor(u, 'mentioned') for u in _.uniq mentioned

    # Report the results.
    transformed = _.map usernames, (u) ->
      r = results[u]
      r ?=
        spoke: 0
        mentioned: 0

      { username: u, spoke: r.spoke.toString(), mentioned: r.mentioned.toString() }
    ordered = _.sortBy transformed, (r) -> parseInt(r.spoke) * -1

    justify = (str, width) ->
      if str.length >= width
        str[0..(width - 3)] + '...'
      else
        justified = str
        for i in [0..(width - str.length)]
          justified += ' '
        justified

    lines = [
      "```"
      "#{justify 'Username', 20}| #{justify 'Spoke', 10}| #{justify 'Mentioned', 10}"
    ]
    for row in ordered
      lines.push "#{justify row.username, 20}| #{justify row.spoke, 10}| #{justify row.mentioned, 10}"
    lines.push "```"

    msg.send lines.join("\n")
