# encoding: utf-8

require 'capistrano'

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        namespace :nginx do

          _cset :nginx_init_path, "/etc/init.d/nginx"

          desc "[internal] Generate Nginx configuration"
          task :generate_configuration, :roles => :web, :except => { :no_release => true } do
            web_server_mode = fetch :web_server_mode
            nginx = Capistrano::Extensions::Server::Nginx.new web_server_mode

            nginx.application = fetch :application
            nginx.public_path = fetch :public_path
            nginx.logs_path   = fetch :logs_path
            nginx.application_url = fetch :application_url
            nginx.denied_access = fetch :denied_access if exists?(:denied_access)
            nginx.rails_env = fetch :rails_env
            nginx.denied_access = fetch :denied_access if exists?(:denied_access)
            nginx.passenger_min_instances = fetch :passenger_min_instances if exists?(:passenger_min_instances)
            nginx.application_redirects = fetch :application_redirects if exists?(:application_redirects)
            nginx.static_urls = fetch(:static_urls,false)
            nginx.ssl_certificate = fetch(:ssl_certificate,false)
            nginx.ssl_certificate_key = fetch(:ssl_certificate_key,false)
            
            if exists?(:web_server_listen_ports)
              nginx.listen_ports = fetch(:web_server_listen_ports)
            elsif exists?(:web_server_listen_port)
              nginx.listen_ports = [fetch(:web_server_listen_port)] 
            else
              nginx.listen_ports = [80]
            end
            
            if exists?(:web_server_auth_file)
              nginx.authentification_file = fetch :web_server_auth_file
            end

            nginx.indexes = fetch(:web_server_indexes) if exists?(:web_server_indexes)

            if exists?(:web_server_mod_rewrite)
              nginx.mod_rewrite = fetch :web_server_mod_rewrite
            end

            if exists?(:php_fpm_host)
              nginx.php_fpm_host = fetch :php_fpm_host
              nginx.php_fpm_port = fetch :php_fpm_port
            end

            # Set the reverse proxy data
            nginx.reverse_proxy_server_address = fetch(:reverse_proxy_server_address) if exists?(:reverse_proxy_server_address)
            nginx.reverse_proxy_server_port = fetch(:reverse_proxy_server_port) if exists?(:reverse_proxy_server_port)

            set :web_conf, nginx
            set :web_conf_contents, nginx.render
          end

          desc "Start nginx web server"
          task :start, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} start
            CMD
          end

          desc "Stop nginx web server"
          task :stop, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} stop
            CMD
          end

          desc "Restart nginx web server"
          task :restart, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} restart
            CMD
          end

          desc "Resload nginx web server"
          task :reload, :roles => :web, :except => { :no_release => true } do
            run <<-CMD
              #{try_sudo} #{fetch :nginx_init_path} reload
            CMD
          end

        end
      end
    end
  end
end