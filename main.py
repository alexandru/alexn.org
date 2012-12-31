#!/usr/bin/env python
# -*- coding: utf-8 -*-

import webapp2

redirects = webapp2.WSGIApplication([
    webapp2.Route(
        '/rss<:[/]?>', webapp2.RedirectHandler, 
        defaults={'_uri':'https://www.bionicspirit.com/atom.xml'}),

    webapp2.Route(
        '/docs/dialer.html', webapp2.RedirectHandler, 
        defaults={'_uri':'https://www.bionicspirit.com/blog/2009/02/20/tips-for-creating-voip-dialer.html'}),
], debug=False)


