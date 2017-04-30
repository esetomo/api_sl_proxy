# config valid only for current version of Capistrano
lock "3.8.0"

set :application, "api_sl_proxy"
set :repo_url, "https://github.com/esetomo/api_sl_proxy.git"

append :linked_dirs, "log", "tmp/pids", "tmp/sockets"

namespace :deploy do
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
end
