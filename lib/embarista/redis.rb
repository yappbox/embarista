require 'uri'

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
      case ENV['YAPP_ENV']
      when 'qa'
        Bundler.with_clean_env do
          `heroku config:get REDISTOGO_URL --app qa-yapp-cedar`.chomp
        end
      when 'prod'
        Bundler.with_clean_env do
          `heroku config:get REDISTOGO_URL --app yapp-cedar`.chomp
        end
      else
        'redis://0.0.0.0:6379/'
      end
    end
  end
end
