# 0.1.3

- Support https and redglass.js 0.3.1
- Update RSpec (3.1.1), ruby (2.1.0) and selenium-webdriver (2.42.0)

# 0.1.2

- Begin using Carryall to conditionally load JavaScript dependencies.
- Do not use jQuery.noConflict().

# 0.1.1

- Explicitly require RedGlassListener.

# 0.1.0

- Capture page state via the RedGlass#take_snapshot method.

# 0.0.6

- Observe WebDriver events by passing in a RedGlassListener to the driver initializer instead of monkey patching.

# 0.0.5

- Implemented observer pattern (via monkey patch) to reload red-glass.js whenever it is cleared from the browser's memory.