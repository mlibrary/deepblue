
require_relative '../../lib/ahoy/tracker' # force the monkeyed version to load first

class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false
