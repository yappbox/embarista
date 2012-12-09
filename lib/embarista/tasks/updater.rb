require 'rake'
require 'rake/tasklib'

module Embarista
  module Updater

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
          FileUtils.cd(app_vendor_path) do
            old_filename = Dir['*'].grep(regexp)[0]
            old_filename =~ regexp
            old_sha = $1
          end
          raise "Couldn't find current ember.js version" if old_sha.nil?
          FileUtils.cd('../ember.js') do
            new_sha = `git rev-parse HEAD`.chomp
            `bundle && bundle exec rake dist`
            FileUtils.cd('./dist') do
              FileUtils.cp('ember.js', "#{app_vendor_path}/ember-#{new_sha}.js")
              FileUtils.cp('ember.min.js', "#{app_vendor_path}/ember-#{new_sha}.min.js")
            end
          end
          if old_sha != new_sha
            FileUtils.cd(app_vendor_path) do
              FileUtils.rm("ember-#{old_sha}.js")
              FileUtils.rm("ember-#{old_sha}.min.js")
            end
            update_asset_file(old_sha, new_sha)
          end
          puts "Updated from #{old_sha} to #{new_sha}"
        end
      end
    end

  end
end
