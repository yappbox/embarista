module Embarista
  module App
    class << self
      def env_var
        'YAPP_ENV'
      end

      def env
        @env ||= (ENV[env_var] || 'dev').to_sym
      end

      def config_by_env
        @config_by_env ||= Yapp.load_config
      end

      def config
        @config ||= config_by_env[env]
      end

      def app_base_url
        @app_base_url ||= "https://#{config.domains.app}"
      end

      def assets_base_url
        @assets_base_url ||= "//#{config.domains.assets_cdn}"
      end

      def assets_bucket
        # asset config is the same on qa and prod
        @assets_bucket ||= config_by_env[:prod].s3.assets_bucket
      end

      def latest_manifest_id
        File.read('tmp/public/LATEST_MANIFEST_ID').chomp rescue nil
      end

      def heroku_app
        @heroku_app ||= case env
        when :qa then 'qa-yapp-cedar'
        when :prod then 'yapp-cedar'
        else nil
        end
      end
    end
  end
end
