app_path = File.expand_path("..", __dir__)
bind "unix://#{app_path}/tmp/sockets/puma.sock"
pidfile "#{app_path}/tmp/pids/puma.pid"
environment 'production'
workers 8
threads 0, 8
