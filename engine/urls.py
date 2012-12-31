from django.conf.urls.defaults import patterns, include, url

from engine import views

urlpatterns = patterns('',
    url(r'^rss/?', views.redirects),
    url(r'^docs/dialer.html?', views.redirects),
)
