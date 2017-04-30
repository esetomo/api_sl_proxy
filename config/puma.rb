_proj_path = File.expand_path("../..", __FILE__)

pidfile "#{_proj_path}/tmp/pids/puma.pid"
state_path "#{_proj_path}/tmp/pids/puma.state"
bind "unix://#{_proj_path}/tmp/sockets/puma.sock"
directory _proj_path

plugin :tmp_restart

