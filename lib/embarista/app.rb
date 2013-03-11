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

      def heruku_app
        @heruku_app ||= case env
        when 'qa' then 'qa-yapp-cedar'
        when 'prod' then 'yapp-cedar'
        else nil
        end
      end
    end
  end
end
