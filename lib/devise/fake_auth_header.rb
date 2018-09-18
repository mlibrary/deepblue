# Bill Deuber pointed to this solution for faking the request headers in
# development and testing environments.  Only add this middleware for those
# environments: in development.rb and test.rb under config/environments/
# config.middleware.use "FakeAuthHeader"
class FakeAuthHeader
  def initialize app
    @app = app
  end

  def call env
    dup._call env
  end

  # duplicating the object to make sure ivars aren't set on the original.
  # consideration for threads. different threads can have their own object
  # (a duped copy) and carry on their merry way.
  def _call env
    env['HTTP_X_REMOTE_USER'] = ENV['USER']
    @app.call(env)
  end

end

