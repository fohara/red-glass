# RedGlass

RedGlass works alongside Selenium to observe browser events, and provides an interactive log which illustrates changes to the DOM during an automation session.  It can be used as a diagnostic tool for writing tests which involve complex browser events and interactions.

## Single Page Usage

To use RedGlass on a single page, simply pass it the driver instance. RedGlass will not be activated for subsequent page loads.

```ruby
driver = Selenium::WebDriver.for :firefox
red_glass = RedGlass.new driver

driver.get "http://google.com"
red_glass.start

driver.find_element(:name, 'q').send_keys 'a'

# Now open http://localhost:4567 in a modern browser to view the event log.
```

## Multi-page Usage

For multi-page usage, you must pass an instance of RedGlassListener to both the driver and RedGlass. RedGlass will then be activated for each subsequent page load.

``` ruby
listener = RedGlassListener.new
driver = Selenium::WebDriver.for :firefox, :listener => listener
red_glass = RedGlass.new driver, {listener: listener}

driver.navigate.to "http://google.com"
red_glass.start
driver.navigate.to "http://news.google.com"

# RedGlass is activated for both pages.
```

## Event Types

RedGlass logs the following types of events:

* click
* keydown
* keyup
* DOMNodeInserted
* DOMNodeRemoved
* xhr (onreadystatechange)
* errors (onerror)

## How it Works

RedGlass loads a javascript application into your browser session which listens for the event types listed above.  When one of those events is fired, the event data is posted to a local server which temporarily persists the data in memory.  The data is then served through
a Web Socket initiated by the client UI.  Just open http://localhost:4567 in a modern browser to view the event log.  Since there is no persistent data store, the event data is lost as soon as it is removed from memory (page refresh, server restart, etc).  This is by design, as RedGlass is intended to be used
as an aide for writing complex UI tests, and not necessarily as a persistent log.

# License

The MIT License - Copyright (c) 2013 Frank O'Hara