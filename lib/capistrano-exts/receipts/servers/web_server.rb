# encoding: utf-8

require 'capistrano'
require 'digest/sha1'

# Require all specific web_server files
Dir["#{File.dirname(__FILE__)}/web_server/*.rb"].each {|f| require f}

# Verify that Capistrano is version 2
unless Capistrano::Configuration.respond_to?(:instance)
  abort "This extension requires Capistrano 2"
end

Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    namespace :server do
      namespace :web_server do
        desc "Setup web server"
        task :setup, :roles => :web do
          # Empty task, server preparation goes into callbacks
        end

        desc "[internal] Generate Web configuration"
        task :generate_web_configuration do
          if exists?(:web_server_app)
            web_server_app = fetch :web_server_app

            case web_server_app
            when :nginx
              find_and_execute_task 'deploy:server:web_server:nginx:generate_configuration'
            when :apache
              find_and_execute_task 'deploy:server:web_server:generate_apache_configuration'
            else
              abort "I don't know how to build '#{web_server_app}' configuration."
            end
          end
        end

        desc "[internal] Generate authentification"
        task :generate_authentification do
          if exists?(:web_server_auth_credentials)
            web_server_auth_credentials = fetch :web_server_auth_credentials
            contents = Array.new

            web_server_auth_credentials.each do |credentials|
              if credentials[:password].is_a?(Proc)
                password = credentials[:password].call.crypt(gen_pass(8))
              else
                password = credentials[:password].crypt(gen_pass(8))
              end
              contents << "#{credentials[:user]}:#{password}"
            end

            set :web_server_auth_file_contents, contents.join("\n")
          end
        end

        desc "[internal] Generate Apache configuration"
        task :generate_apache_configuration do
          # TODO: Write Apache config generator
        end

        desc "[internal] Write authentification file"
        task :write_web_server_auth_file do
          if exists?(:web_server_auth_file)
            web_server_auth_file = fetch :web_server_auth_file
            web_server_auth_file_contents = fetch :web_server_auth_file_contents
            random_file = "/tmp/#{fetch :application}_#{Digest::SHA1.hexdigest web_server_auth_file_contents}"

            run <<-CMD
              #{try_sudo} mkdir -p #{File.dirname web_server_auth_file}
            CMD

            put web_server_auth_file_contents, random_file

            run <<-CMD
              #{try_sudo} mv #{random_file} #{web_server_auth_file}
            CMD
          end
        end

        desc "[internal] Write web configuration file"
        task :write_web_conf_file do
          if exists?(:web_conf_file)
            web_conf_file = fetch :web_conf_file
            random_file = "/tmp/#{fetch :application}_#{Digest::SHA1.hexdigest web_conf_contents}"

            run <<-CMD
              #{try_sudo} mkdir -p #{File.dirname web_conf_file}
            CMD

            put web_conf_contents, random_file

            run <<-CMD
              #{try_sudo} mv #{random_file} #{web_conf_file}
            CMD
          end
        end

        task :finish do
          # Empty task for callbacks
        end
      end
    end
  end

  before "deploy:server:web_server:setup", "deploy:server:web_server:generate_web_configuration"
  after  "deploy:server:web_server:setup", "deploy:server:web_server:finish"
  after "deploy:server:web_server:generate_web_configuration", "deploy:server:web_server:generate_authentification"
  after "deploy:server:web_server:generate_web_configuration", "deploy:server:web_server:write_web_conf_file"
  after "deploy:server:web_server:generate_authentification", "deploy:server:web_server:write_web_server_auth_file"
end