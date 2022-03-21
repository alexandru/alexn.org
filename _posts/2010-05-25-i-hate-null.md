---
title: I hate NULL and all its variants!
date:   2010-05-25
tags:
  - Python
image: /assets/media/articles/beautiful-soup.png
---

<p class="intro withcap" markdown='1'>
    How many times have you had a chain of methods like this (example showing [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/) in action) ...
</p>

```python
soup.find('table', {'class':'search-params'})\
    .findParent('form')\
    .find('td', {'class': 'elem'})\
    .find('input')\
    .get('name')
```

BeautifulSoup is not JQuery, and when it doesn't find an element on find actions, it just returns None or an empty list. Then you get a beautiful index error or a method not available on NoneType kind of error, with the result being that the error itself doesn't say anything useful about what happened (except the source-code line number) ... whereas in the case above I would probably prefer a WebUIError or something.

And really, most of the time I just want the result of such an expression to be None, in case one method invocation fails, and I do not think that having a try/except block for every line of code that does something interesting is ideal.

Fortunately Python is dynamic, and you can come up with something resembling the [Maybe monad](http://en.wikipedia.org/wiki/Monad_(functional_programming)#Maybe_monad). Here's one way to do it ...

1.  instead of sending invocations to your initial object / collection (in my case a BeautifulSoup object used for querying), you're sending them to a proxy
2.  for each invocation type you want, the proxy stores the invocation types into a list
3.  when you want to execute the resulting expression, you iterate through that list actually invoking those actions, keeping an intermediate result
4.  if at any point that intermediate result becomes None (or something that evaluates to False) or an exception is thrown, then you can either invoke some handler (specializing the exception thrown) or you can return None

There are 3 types of invocations I needed to work with BeautifulSoup ...

1.  attribute access (overridden with `__getattr__`)
2.  method invocation (overridden with `__call__`)
3.  indexer (overridden with `__getitem__` and `__setitem__`)

My proxy implementation starts something like this ...

```python
class Proxy(object):
    def __init__(self, instance, on_error_callback = None, _chain=None, _memo=None):
        self._wrapped_inst = instance
        self._chain = _chain or []
        self._on_error_callback = on_error_callback
        self._memo = _memo or []

    def __getattr__(self, name):
        return self._new_proxy(ProxyAttribute(name))

    def __call__(self, *args, **kwargs):
        return self._new_proxy(ProxyInvoke(args, kwargs))
```

As you can see, there's an _instance_ of an object getting wrapped (`_wrapped_instance`), there's a `_chain` of expressions memorized, there's an `_on_error_callback` that gets executed in case of error, and there's a `_memo` that keeps the result of the last execution (libraries like BeautifulSoup are slow).

Of course, I'm getting fancy, because I want [memoization](https://en.wikipedia.org/wiki/Memoization) and because in order to prevent the proxy getting into an inconsistent state, when adding a new invocation type to the `_chain` I'm taking a page from functional programming by creating a new proxy object (making the proxy somewhat immutable).

So I override `__getattr__` and `__call__` and `__getitem__` and `__setitem__`. For example on `__getattr__` I add to `_chain` an instance of a `ProxyAttribute`, which looks something like this ...

```python
class ProxyAttribute(object):
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return "." + self.name

    def do(self, obj):
        return getattr(obj, self.name)
```

And when I want the result of such invocation, if the intermediate result is stored in `obj`, then it would look like ...

```python
obj = proxy_attribute_instance.do(obj)
```

Now, for how it would look in practice ...

```python
def handler_soup_error(**kwargs):
     raise WebUIError("Web interface specification changed")

soup = Proxy(BeautifulSoup(document), handler_soup_error)

soup.find('table', {'class':'search-params'}).findParent('form')\
    .find('td', {'class': 'elem'})\
    .find('input')\
    .get('name')\
    .do()
```

So at the actual call site, the only difference is that `do()` call. If the error handler wouldn't be specified, the result returned would be `None`. Simple as that.

I also needed an utility, because I want to capture a partial evaluation to not rerun it for multiple special cases (like in the above case capturing all "td" elements) ...

```python
all_td_elems = soup.find('table', {'class':'search-params'})\
    .findParent('form')\
    .find('td', {'class': 'elem'})\
    .do_cache() # not an inspiring name unfortunately

    # and then resume with the same behavior ...
    all_td_elements.find('input').get('name').do()
```

Yeah, it's just a small hack, but it's so damn useful sometimes. 

See [full code snippet]({% link _snippets/2020-07-30-python-proxy.py.md %}) for copy/pasting.
