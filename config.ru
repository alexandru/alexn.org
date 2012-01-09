# Redirects requests from bionicspirit.com to alexn.org

class Redirects
  def initialize(*args)
  end

  def each(&block)
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.fullpath

    [301, {'Location' => "http://alexn.org#{path}"}, self]
  end
end

run Redirects.new
