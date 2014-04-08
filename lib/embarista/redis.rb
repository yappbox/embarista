require 'uri'
require 'timeout'

module Embarista
  module Redis
    def self.client
      $redis ||= begin
        uri = URI.parse(url)
        require 'redis'
        ::Redis.new(
          :host => uri.host,
          :port => uri.port,
          :password => uri.password
        )
      end
    end

    def self.url
      ENV['REDISTOGO_URL'] ||= fetch_url
    end

    def self.fetch_url
      if App.heroku_app
        Bundler.with_clean_env do
          Timeout::timeout(30) do
            `heroku config:get REDISTOGO_URL --app #{App.heroku_app}`.chomp
          end
        end
      else
        'redis://0.0.0.0:6379/'
      end
    end
  end
end
