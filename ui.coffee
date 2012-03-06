

class HckrUI extends EventEmitter
  constructor: (@root) ->
    @root.on 'newMessageIn', @newMessage
    @root.on 'buddyListReset', @buddyListReset
    @root.on 'buddyStatusChange', @buddyStatusChange
    @root.on 'buddyTypingStatus', @buddyTypingStatus
    @initialize()

  # Do not change this method. Simply call it any time you're ready to send
  # a message.
  newMessageOut: (protocol, recipient, sender, message) =>
    @emit 'newMessageOut', protocol, recipient, sender, message

  initialize: =>
    # extend this and do some initialization in it.
    # You'll need some kind of loop to accept user input.

  newMessage: (protocol, recipient, sender, message) =>
    # extend this method, and do your own shit.

  # This method is called any time a buddy's status changes.
  buddyStatusChange: (protocol, buddy, oldStatus, newStatus) =>
    # extend this method, and do your own shit.

  # This method is called any time a protocol has a successful signon.
  buddyListReset: (protocol, newList) =>
    # extend this method, and do your own shit.

  # This method is called any time a buddy begins or stops typing.
  buddyTypingStatus: (protocol, buddy, isTyping) =>
    # extend this method, and do your own shit.

