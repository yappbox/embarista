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
        update_ember_task = task name do |t, args|
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
            Bundler.with_clean_env do
              `bundle && bundle exec rake dist`
            end
            cd('./dist') do
              cp('ember.js', "#{app_vendor_path}/ember-#{new_sha}.js")
              cp('ember.min.js', "#{app_vendor_path}/ember-#{new_sha}.min.js")
              cp('ember-template-compiler.js', "#{app_vendor_path}/ember-template-compiler-#{new_sha}.js")
            end
          end
          if old_sha != new_sha
            cd(app_vendor_path) do
              rm("ember-#{old_sha}.js")
              rm("ember-#{old_sha}.min.js")
              rm("ember-template-compiler-#{old_sha}.js")
            end
            Embarista::Updater.update_asset_file(old_sha, new_sha)
          end
          puts "Updated from #{old_sha} to #{new_sha}"
        end
        update_ember_task.add_description "Update Ember from a repo in ../ember.js"
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
        update_ember_data_task = task name do |t, args|
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
            Bundler.with_clean_env do
              `bundle && bundle exec rake dist`
            end
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
        update_ember_data_task.add_description "Update Ember data from a repo in ../ember-data"
      end
    end

    class UpdateEmberStatesTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_ember_states)
        @name = name
        yield self if block_given?
        define
      end

      def define
        update_ember_states_task = task name do |t, args|
          old_sha, new_sha = nil, nil
          regexp = /ember-states-([0-9a-f]{40})/
          app_vendor_path = File.expand_path("app/vendor")
          cd(app_vendor_path) do
            old_filename = Dir['*'].grep(regexp)[0]
            old_filename =~ regexp
            old_sha = $1
          end
          raise "Couldn't find current ember-states js version" if old_sha.nil?
          cd('../ember-states') do
            new_sha = `git rev-parse HEAD`.chomp
            Bundler.with_clean_env do
              `bundle && bundle exec rake dist`
            end
            cd('./dist') do
              cp('ember-states.js', "#{app_vendor_path}/ember-states-#{new_sha}.js")
              cp('ember-states.min.js', "#{app_vendor_path}/ember-states-#{new_sha}.min.js")
            end
          end
          if old_sha != new_sha
            cd(app_vendor_path) do
              rm("ember-states-#{old_sha}.js")
              rm("ember-states-#{old_sha}.min.js")
            end
            Embarista::Updater.update_asset_file(old_sha, new_sha)
          end
          puts "Updated from #{old_sha} to #{new_sha}"
        end
        update_ember_states_task.add_description "Update Ember States from a repo in ../ember-states"
      end
    end

    class UpdateQunitTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_qunit)
        @name = name
        yield self if block_given?
        define
      end

      def define
        update_qunit_task = task name do |t, args|
          version = ENV['VERSION']
          raise "please supply VERSION env var to specify QUnit version (specify \"git\" for nightly)" if version.nil?
          cd('./test/vendor') do
            # remove old qunit
            rm Dir['qunit-*.js']
            rm Dir['qunit-*.css']
            sh "curl -O http://code.jquery.com/qunit/qunit-#{version}.js"
            sh "curl -O http://code.jquery.com/qunit/qunit-#{version}.css"
          end
          puts "Updated to QUnit #{version}"
        end
        update_qunit_task.add_description "Update QUnit to VERSION from code.jquery.com"
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
        update_jquery_task = task name do |t, args|
          version = ENV['VERSION']
          raise "please supply VERSION env var to specify jQuery version" if version.nil?
          cd('./app/vendor') do
            # remove old jquerys
            rm Dir['jquery-*.js']
            sh "curl -O http://code.jquery.com/jquery-#{version}.js"
            sh "curl -O http://code.jquery.com/jquery-#{version}.min.js"
          end
          Embarista::Updater.update_asset_file(%r{JQUERY_VERSION = '[^']+'}, "JQUERY_VERSION = '#{version}'")
          puts "Updated to jQuery #{version}"
        end
        update_jquery_task.add_description "Update jQuery to VERSION from code.jquery.com"
      end
    end

    class UpdateHandlebarsTask < ::Rake::TaskLib
      attr_accessor :name

      def initialize(name = :update_handlebars)
        @name = name
        yield self if block_given?
        define
      end

      def define
        update_handlebars_task = task name do |t, args|
          version = ENV['VERSION']
          raise "please supply VERSION env var to specify Handlebars version (specify \"git\" for nightly)" if version.nil?
          cd('./app/vendor') do
            # remove old qunit
            rm Dir['handlebars-*.js']
            rm Dir['handlebars.runtime-*.js']
            sh "curl http://builds.handlebarsjs.com.s3.amazonaws.com/handlebars-#{version}.js > handlebars-#{version}.js"
            sh "curl http://builds.handlebarsjs.com.s3.amazonaws.com/handlebars.runtime-#{version}.js > handlebars.runtime-#{version}.js"
            sh "uglifyjs < handlebars.runtime-#{version}.js > handlebars.runtime-#{version}.min.js"
          end
          Embarista::Updater.update_asset_file(%r{HANDLEBARS_VERSION = '[^']+'}, "HANDLEBARS_VERSION = '#{version}'")
          puts "Updated to Handlebars #{version}"
        end
        update_handlebars_task.add_description "Update Handlebars to VERSION from github.com/wycats/handlebars.js"
      end
    end

  end
end
