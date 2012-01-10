import webapp2
from google.appengine.api import urlfetch

class PingService(webapp2.RequestHandler):
  def get(self):
      self.response.headers['Content-Type'] = 'text/plain'

      url = "http://bionicspirit.com/ping"
      try:
          result = urlfetch.fetch(url, deadline=30)
          self.response.out.write('HTTP %d - %s' % (result.status_code, (result.content or '').strip()))
      except:
          self.response.out.write('ERROR: no response')

app = webapp2.WSGIApplication([('/tasks/ping', PingService)], debug=False)
