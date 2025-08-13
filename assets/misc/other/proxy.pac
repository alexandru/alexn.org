function FindProxyForURL(url, host) {
    // SOCKS5 proxy with authentication
    var proxy = "SOCKS5 nl.socks.nordhold.net:1080";
    
    // For DNS resolution through the proxy
    if (isResolvable(host)) {
        return proxy;
    }
    
    // Direct connection for local addresses
    if (isPlainHostName(host) || isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0")) {
        return "DIRECT";
    }
    
    return proxy;
}