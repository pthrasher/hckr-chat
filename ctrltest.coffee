tui = require 'node-term-ui'

process.on 'SIGINT', ->
    tui.quit()

tui.pos tui.height / 2, tui.width / 2
tui.out "yo yo homes"


