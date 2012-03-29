tui = require 'TermUI'

headerText = "Welcome to hckr chat"
messages = []
inputBuf = ""

# returns array of lines
wordWrap = (str, width) ->
  re = '.{1,' + width + '}(\\s|$)|\\S+?(\\s|$)'
  return (str.match (RegExp re, 'g'))

cleanup = ->
  tui.quit()
  process.exit 0

hline = (y) ->
    #draws a horizontal line.
    tui.pos 1, y

printBuf = ->
  lines = wordWrap inputBuf, tui.width()

  inputHeight = lines.length
  inputStart = window.height - inputHeight
  finalLineLen = lines[lines.length - 1].length


  for line, i in lines
    row = window.height - (lines.length - i)
    window.cursor row, 0
    window.clrtoeol()
    window.print row, 0, line

  window.cursor row, lines[lines.length - 1].length
  window.touch()

bindWindowEvents = (window) ->
  window.hline window.height - 2, 0, window.width
  window.setscrreg 1, window.height - (inputBufLineHeight + 1)
  window.cursor window.height - 1, 0
  window.touch()
  window.refresh()

  tui.on 'inputChar', (char, keyCode) ->
    # first make sure this is an appropriate char.
    if char.match /[a-zA-Z0-9`~!@#$%\^&*()_+-=\[\]{}|;':",.<>\/? ]/
      inputBuf += char
      printBuf window
      window.refresh()


process.on 'SIGINT', ->
  cleanup()

process.on 'uncaughtException', (err) ->
  cleanup()






