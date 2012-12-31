#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
from django.shortcuts import Http404
from django.http import HttpResponse

def redirects(request):
    full_path = request.get_full_path()

    response = HttpResponse(status=301)
    response['Cache-control'] = "public, max-age=" + str(60 * 60 * 24 * 365)

    if re.match("^/rss/?", full_path):
        response["Location"] = "https://www.bionicspirit.com/atom.xml"

    elif re.match("^/docs/dialer.html?", full_path):
        response["Location"] = "https://www.bionicspirit.com/blog/2009/02/20/tips-for-creating-voip-dialer.html"

    else:
        raise Http404

    return response



