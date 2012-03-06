# Red Glass

Red Glass works alongside Selenium to observe browser events, and provides an interactive log which illustrates changes to the DOM during an automation session.  It can be used as a diagnostic tool for writing tests which involve complex browser events and interactions.

## Usage

```ruby
driver = Selenium::WebDriver.for :firefox
red_glass = RedGlass.new driver

driver.get "http://google.com"
red_glass.start

driver.find_element(:name, 'q').send_keys 'a'

#Now open http://localhost:4567 in a modern browser to view the event log.
```

## Event Types

Red Glass logs the following types of events:

* click
* keydown
* keyup
* DOMNodeInserted
* DOMNodeRemoved
* xhr (onreadystatechange)
* errors (onerror)

## How it Works

Red Glass loads a javascript application into your browser session which listens for the event types listed above.  When one of those events is fired, the event data is posted to a local server which temporarily persists the data in memory.  The data is then served through
a Web Socket initiated by the client UI.  Just open http://localhost:4567 in a modern browser to view the event log.  Since there is no persistent data store, the event data is lost as soon as it is removed from memory (page refresh, server restart, etc).  This is by design, as Red Glass is intended to be used
as an aide for writing complex UI tests, and not necessarily as a persistent log.

# License

The MIT License - Copyright (c) 2012 Frank O'Hara