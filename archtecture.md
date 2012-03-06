This doc is meant to describe the process flow / architecture of the app
itself, and how we'll handle communication between different pieces.

It's written in coffee script, and runs on node. It's event driven, and
asynchronus. In broad view, you have a few tiers of plugins, and a main
codebase that manages the plugins, and kind of glues it all together. The
plugin classes are:

* UI Plugin (can only have one)
* Encryption plugin (can only have one)
* Protocol Plugin (can have many) (aka adapters)
* input plugins (can have many) (modify incoming messages)
* output plugins (can have many) (modify outgoing message)

The main app has it's own chat system that handles message recv, send, etc. The
adapters are merely bridges between that system, and the real chat protocols.

Preemptive note:
_All plugins inheret from a predefined base class specific to each class of
function. The predefined base class binds itself to all standard events inside
the contructor. Plugin authors need only override the standard methods that the
event bindings are set to call._

Application Procedural Flow
---------------------------

1. Main application module loads.
   1. Load config file, parse settings.
   1. Load UI plugin.
   1. Load encryption plugin. All events are bound by base class similar to UI
      plugin.
   1. Load in all input plugins.
   1. Load all output plugins.
   1. Load all protocol adapters.
   1. Connect to each protocol via configured settings. Protocol plugins only
      get instantiated if they're configured to be connected to.
   1. Final note - Plugin event binding happens in the constructor -- always on
      plugin instantiation.

Preemptive note:
_Main app code binds to adapter events upon instantiation of protocol._

Message Received Procedural Flow
--------------------------------

1. Protocol Adapter is first responder.
1. Main app receives message, and hands message to encryption plugin.
1. Encryption plugin is responsible for determining if the message is
   encrypted.
1. Once encryption plugin is finished, it raises an event which the main app
   code picks up.
1. Main app code raises an event for each input plugin which are capable of
   modifying the message.
1. Once all input plugins have been run, the main app raises an event which the
   UI plugin is bound to.
1. The UI plugin renders the message.

Message Sending Procedural Flow
-------------------------------

1. UI plugin takes input of some kind.
1. UI plugin emits event, passing message to main app with proper routing info
   (protocol, username, recipient, message)
1. Main app passes the message through each output plugin which are each
   capable of modifying the message.
1. Once all output plugins have been executed, the message is passed to the
   encryption plugin.
1. Once encryption plugin is done, an event is emitted, and the main app routes
   the message to the appropriate protocol, and connection.

Specification for input plugins
-------------------------------

Input plugins handle incoming messages. They are a simple plugin that has
a function named `run` that takes the parameters protocolName, sender,
recipient, message text. They return message text either modified, or
unmodified. If this method returns nothing, the main app will treat it the same
as returning the message untouched.

Specification for output plugins
--------------------------------

Output plugins are the same as input plugins, and receive the same arguments.
They simply handle what a user is sending to someone else rather than what
a user is receiving from their friends.

