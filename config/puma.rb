_proj_path = File.expand_path("../..", __FILE__)

pidfile "#{_proj_path}/tmp/pids/puma.pid"
bind "unix://#{_proj_path}/tmp/sockets/puma.sock"
directory _proj_path

plugin :tmp_restart

