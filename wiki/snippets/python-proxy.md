# Python Proxy Sample

```python
class ProxyAttribute(object):
    def __init__(self, name):
        self.name = name
    def __repr__(self):
        return "." + self.name

    def do(self, obj):
        return getattr(obj, self.name)

class ProxyInvoke(object):
    def __init__(self, args, kwargs):
        self.args = args
        self.kwargs = kwargs

    def __repr__(self):
        args_str   = ', '.join(self.args)
        kwargs_str = ', '.join([ "%s=%s" % (k, self.kwargs[k]) for k in self.kwargs.keys() ])

        args_list = []
        if args_str: args_list.append(args_str)
        if kwargs_str: args_list.append(kwargs_str)

        return "  invoke(%s)" % ', '.join(args_list)

    def do(self, obj):
        return obj(*self.args, **self.kwargs)

class ProxyInvokeIndex(object):
    def __init__(self, key, value=None, set_value=False):
        self.key = key
        self.value = value
        self.set_value = set_value
    def __repr__(self):
        if not self.set_value:
            return "  __getitem__(%s)" % str(self.key)
        else:
            return "  __setitem__(%s, %s)" % (str(self.key), str(self.value))
    def do(self, obj):
        if not self.set_value:
            return obj[self.key]
        obj[self.key] = self.value

class Proxy(object):

    def __init__(self, instance, on_error_callback = None, _chain=[], _memo=[]):
        self._wrapped_inst = instance
        self._chain = _chain
        self._on_error_callback = on_error_callback
        self._memo = _memo

    def __getattr__(self, name):
        return self._new_proxy(ProxyAttribute(name))

    def __call__(self, *args, **kwargs):
        return self._new_proxy(ProxyInvoke(args, kwargs))

    def __getitem__(self, key):
        return self._new_proxy(ProxyInvokeIndex(key))
    def __setitem__(self, key, value):
        return self._new_proxy(ProxyInvokeIndex(key, value, True))

    def _new_proxy(self, *appended):
        newc = [ x for x in self._chain ]
        for x in appended: newc.append(x)
        newm = [x for x in self._memo]
        return Proxy(self._wrapped_inst, self._on_error_callback, newc, newm)

    def do_cache(self, should_exist=False):
        self.do(should_exist)
        return self

    def do(self, should_exist=False):
        ret = self._wrapped_inst

        step_idx = 0
        for step in self._chain:
            if len(self._memo) > step_idx:
                if step_idx + 1 == len(self._memo):
                    ret = self._memo[step_idx]
            else:
                try:
                    ret = step.do(ret)
                    if should_exist and not ret:
                        raise TypeError("returned value was nulls")
                    self._memo.append(ret)
                except Exception, e:
                    if self._on_error_callback:
                        return self._on_error_callback(exc=e, obj=ret, step=step)
                    else:
                        raise
            step_idx += 1

        return ret

    def __repr__(self):
        str = "[Proxy Invocation: \n"
        for o in self._chain:
            str += '  ' + repr(o) + "\n"
        return str + ']'
```