app_path = File.expand_path("..", __dir__)
bind "unix:///#{app_path}/tmp/sockets/puma.sock"
environment 'production'
workers 8
threads 0, 8
