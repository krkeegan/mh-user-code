# Update only a single item in the iPhone web
# meant to be called by an ajax script

# Authority: anyone

return "HTTP/1.0 200 OK\nContent-Type: text/html\n\n" . &html5WebApp('Main','states');
