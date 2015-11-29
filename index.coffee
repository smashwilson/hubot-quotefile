fs = require 'fs'
path = require 'path'

module.exports = (robot, scripts) ->
  srcPath = path.resolve(__dirname, 'src')

  if scripts? and '*' not in scripts
    robot.loadFile(srcPath, 'quote.coffee') if 'quote.coffee' in scripts
  else
    robot.loadFile(srcPath, 'quote.coffee')
