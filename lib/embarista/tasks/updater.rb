require 'rake'
require 'rake/tasklib'

module Embarista
  module Updater
    extend self
    def update_asset_file(regexp, replacement)
      assetfile_contents = File.read('Assetfile')
      assetfile_contents.gsub!(regexp, replacement)
      File.open('Assetfile', 'w') do |f|
        f.write(assetfile_contents)
      end
    end

    class UpdateEmberTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_ember)
        @name = name
        yield self if block_given?
        define
      end

      def define
        task name do |t, args|
          old_sha, new_sha = nil, nil
          regexp = /ember-([0-9a-f]{40})/
          app_vendor_path = File.expand_path("app/vendor")
          cd(app_vendor_path) do
            old_filename = Dir['*'].grep(regexp)[0]
            old_filename =~ regexp
            old_sha = $1
          end
          raise "Couldn't find current ember.js version" if old_sha.nil?
          cd('../ember.js') do
            new_sha = `git rev-parse HEAD`.chomp
            `bundle && bundle exec rake dist`
            cd('./dist') do
              cp('ember.js', "#{app_vendor_path}/ember-#{new_sha}.js")
              cp('ember.min.js', "#{app_vendor_path}/ember-#{new_sha}.min.js")
            end
          end
          if old_sha != new_sha
            cd(app_vendor_path) do
              rm("ember-#{old_sha}.js")
              rm("ember-#{old_sha}.min.js")
            end
            Embarista::Updater.update_asset_file(old_sha, new_sha)
          end
          puts "Updated from #{old_sha} to #{new_sha}"
        end
      end
    end

    class UpdateEmberDataTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_ember_data)
        @name = name
        yield self if block_given?
        define
      end

      def define
        task name do |t, args|
          old_sha, new_sha = nil, nil
          regexp = /ember-data-([0-9a-f]{40})/
          app_vendor_path = File.expand_path("app/vendor")
          cd(app_vendor_path) do
            old_filename = Dir['*'].grep(regexp)[0]
            old_filename =~ regexp
            old_sha = $1
          end
          raise "Couldn't find current ember-data js version" if old_sha.nil?
          cd('../ember-data') do
            new_sha = `git rev-parse HEAD`.chomp
            `bundle && bundle exec rake dist`
            cd('./dist') do
              cp('ember-data.js', "#{app_vendor_path}/ember-data-#{new_sha}.js")
              cp('ember-data.min.js', "#{app_vendor_path}/ember-data-#{new_sha}.min.js")
            end
          end
          if old_sha != new_sha
            cd(app_vendor_path) do
              rm("ember-data-#{old_sha}.js")
              rm("ember-data-#{old_sha}.min.js")
            end
            Embarista::Updater.update_asset_file(old_sha, new_sha)
          end
          puts "Updated from #{old_sha} to #{new_sha}"
        end
      end
    end

    class UpdateJqueryTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_jquery)
        @name = name
        yield self if block_given?
        define
      end

      def define
        task name do |t, args|
          version = ENV['VERSION']
          raise "please supply VERSION env var to specify jQuery version" if version.nil?
          cd('./app/vendor') do
            # remove old jquerys
            rm Dir['jquery-*.js']
            sh "curl -O http://code.jquery.com/jquery-#{version}.js"
            sh "curl -O http://code.jquery.com/jquery-#{version}.min.js"
          end
          Embarista::Updater.update_asset_file(%r{JQUERY_VERSION = '\d+\.\d+\.\d+'}, "JQUERY_VERSION = '#{version}'")
          puts "Updated to jQuery #{version}"
        end
      end
    end

  end
end
