util = require 'util'
tty = require 'tty'
fs = require 'fs'
{EventEmitter} = require 'events'


COLORS =
    black: 0
    red: 1
    green: 2
    yellow: 3
    blue: 4
    magenta: 5
    cyan: 6
    white: 7
    default: 9

STYLES =
    normal: 0
    bold: 1
    underline: 4
    blink: 5
    inverse: 8


SYMBOLS =
    star: '\u2605'
    check: '\u2714'
    x: '\u2718'
    triUp: '\u25b2'
    triDown: '\u25bc'
    triLeft: '\u25c0'
    triRight: '\u25b6'
    fn: '\u0192'
    arrowUp: '\u2191'
    arrowDown: '\u2193'
    arrowLeft: '\u2190'
    arrowRight: '\u2192'
    boxTL: '\u2513'
    boxTR: '\u250F'
    boxBL: '\u2517'
    boxBR: '\u251B'
    boxHL: '\u2501'
    boxVL: '\u2503'


class Screen extends EventEmitter
    constructor: ->
        if tty.isatty process.stdin
            # we're gonna need a log since I'm debugging.
            @logstream = fs.createWriteStream 'termsies.lawg',
                flags: 'a+'
                encoding: 'utf8'

            tty.setRawMode true
            process.stdin.resume()

            process.stdin.on 'keypress', @handleKeypress
            process.stdin.on 'data', @handleData

            if process.listeners('SIGWINCH').length is 0
                process.on 'SIGWINCH', @handleSizeChange

            @handleSizeChange()

            @enableMouse()
            @isTerm = true
            @log 'constructor is done'
        else
            @isTerm = false

    handleSizeChange: =>
        winsize = process.stdout.getWindowSize()
        @width = winsize[0]
        @height = winsize[1]
        @emit 'resize', {width: @width, height: @height}

    out: (buf) ->
        if @isTerm
            process.stdout.write(buf)
        @

    hideCursor: ->
        @out '\x1b[?25l'

    showCursor: ->
        @out '\x1b[?25h'

    clear: ->
        @out '\x1b[2J'
        @home
        @

    saveCursor: ->
        if not @cursorSaved
            @out "\x1b[s"
            @cursorSaved = yes
        @

    restoreCursor: ->
        if @cursorSaved
            @out "\x1b[u"
            @cursorSaved = no
        @

    pos: (x, y) ->
        x = if x < 0 then @width - x else x
        y = if y < 0 then @height - y else y
        x = Math.max(Math.min(x, @width), 1)
        y = Math.max(Math.min(y, @height), 1)
        @out "\x1b[#{y};#{x}f"
        @

    home: ->
        @pos 1, 1
        @

    end: ->
        @pos 1, -1
        @

    fg: (c) ->
        @out "\x1b[3#{c}m"
        @

    bg: (c) ->
        @out "\x1b[4#{c}m"
        @

    hifg: (c) ->
        @out "\x1b[38;5;#{c}m"
        @

    hibg: (c) ->
        @out "\x1b[48;5;#{c}m"
        @

    colorize: (str, fg, bg=COLORS.default) ->
        return "\x1b[3#{fg}m\x1b[4#{bg}m#{str}\x1b[3#{COLORS.default}m\x1b[4#{COLORS.default}m"

    enableMouse: ->
        @out '\x1b[?1000h'
        @out '\x1b[?1002h'
        @

    disableMouse: ->
        @out '\x1b[?1000l'
        @out '\x1b[?1002l'
        @

    eraseLine: ->
        @out '\x1b[2K'
        @

    hline: (y, len) ->
        @saveCursor()
        for x in [1..len]
            @pos x, y
            @out SYMBOLS.boxHL
        @restoreCursor()
        @

    handleKeypress: (c, key) =>
        if (key && key.ctrl && key.name == 'c')
            @emit 'SIGINT'
        else
            @emit 'keypress', c, key

    handleData: (d) =>
        @log "got some data"
        eventData = {}
        buttons = [ 'left', 'middle', 'right' ]

        if d[0] is 0x1b and d[1] is 0x5b && d[2] is 0x4d # mouse event

            switch (d[3] & 0x60)

                when 0x20 # button
                    if (d[3] & 0x3) < 0x3
                        event = 'mousedown'
                        eventData.button = buttons[ d[3] & 0x3 ]
                    else
                        event = 'mouseup'

                when 0x40 # drag
                    event = 'drag'
                    if (d[3] & 0x3) < 0x3
                        eventData.button = buttons[ d[3] & 0x3 ]

                when 0x60 # scroll
                    event = 'wheel'
                    if d[3] & 0x1
                        eventData.direction = 'down'
                    else
                        eventData.direction = 'up'
                else
                    @log util.inspect d


        eventData.shift = (d[3] & 0x4) > 0
        eventData.x = d[4] - 32
        eventData.y = d[5] - 32

        @emit event, eventData
        @emit 'any', event, [eventData]

    log: (msg) ->
        @logstream.write "#{msg}\n"

    quit: (qmsg) ->
        @fg(COLORS.default).bg(COLORS.default)
        @disableMouse()
        @showCursor()
        @clear()
        tty.setRawMode(false)
        @


class Tab extends EventEmitter
    constructor: (@scr, @title) ->
        @buf = ""
        @inputTop = @scr.height
        @log = []
        @inputLines = ['']



    handleKeypress: (c, kc) =>
        if c.match /[a-zA-Z0-9`~!@#$%\^&*()_+-=\[\]{}|;':",.<>\/? ]/
            @buf += c
            @drawInput()
        else
            if kc.name == 'backspace'
                @buf = @buf.substring 0, @buf.length - 1
                @drawInput()
            else if kc.name == 'enter'
                if @buf.length > 0
                    if @buf == "/nexttab"
                        @buf = ""
                        @inputLines = ['']
                        @emit 'nextTab'
                    else
                        buf = "#{@scr.colorize 'You', COLORS.blue}: #{@buf}"
                        lines = @wrap buf
                        for line in lines
                            @log.push line
                        @buf = ""
                        @inputLines = ['']
                        @drawInput()
                        @drawLog()
            @scr.log "kc: #{util.inspect kc}"


    drawTitle: ->
        @scr.hideCursor()

        titleStart = Math.floor(@scr.width / 2) - Math.floor(@title.length / 2)

        @scr.pos titleStart, 1
        @scr.out @title
        @scr.showCursor()

    drawLog: ->
        @scr.hideCursor()
        scr.hline 2, scr.width
        scr.hline @inputTop - 1, @scr.width
        a = @inputTop - 2
        i = @log.length - 1
        until a == 2 or i < 0
            @scr.pos 1, a
            @scr.eraseLine()
            @scr.out @log[i]
            a--
            i--

        @resetInputCursor()

    wrap: (str) ->
        re = '.{1,' + @scr.width + '}(\\s|$)|\\S+?(\\s|$)'
        return (str.match (RegExp re, 'g'))

    drawInput: ->
        @scr.hideCursor()
        lines = @wrap @buf
        
        if lines
            inpTop = @scr.height - (lines.length - 1)
        else
            inpTop = @scr.height
            lines = ['']


        for line, i in lines
            @scr.pos 1, i + inpTop
            @scr.eraseLine()
            @scr.out line

        if inpTop isnt @inputTop
            @inputTop = inpTop
            @drawLog()
        
        @inputLines = lines
        @resetInputCursor()

    resetInputCursor: ->
        lines = @inputLines
        @scr.pos lines[lines.length - 1].length + 1, @scr.height
        @scr.showCursor()

    hide: ->
        @scr.removeListener 'keypress', @handleKeypress
        @scr.clear()

    show: ->
        @drawTitle()
        @drawLog()
        @drawInput()
        @scr.on 'keypress', @handleKeypress
        
class TabManager
    constructor: ->
        @tabs = []
        @currentTab = 0

    nextTab: =>
        if @tabs.length > 1
            @changeTab((@currentTab + 1) % @tabs.length)

    prevTab: =>
        if @tabs.length > 1
            @changeTab((@currentTab - 1) % @tabs.length)

    changeTab: (idx) ->
        @tabs[@currentTab].hide()
        @tabs[@currentTab].removeListener 'nextTab', @nextTab
        @currentTab = idx
        @tabs[@currentTab].show()
        @tabs[@currentTab].on 'nextTab', @nextTab

    addTab: (tab) ->
        @tabs.push tab
        @changeTab @tabs.length - 1




scr = null

handleSIGINT = ->
    process.stdin.destroy()
    scr.quit()
    console.log "Got tha sig int..."
    process.exit(0)

process.on 'SIGINT', handleSIGINT


scr = new Screen()

scr.on 'SIGINT', handleSIGINT

scr.clear()

t = new Tab scr, "Chat with Chris Moultrie"
tt = new Tab scr, "Chat with Philip Thrasher"

tm = new TabManager()
tm.addTab t
tm.addTab tt


