require 'thread'
require 'rack/lock'
require 'rake-pipeline'
require 'listen'
require 'securerandom'
require 'ruby_gntp'

module Embarista
  class Server
    def initialize(opts = {})
      @root = opts[:root]
      @project_name = opts[:project_name] || File.basename(@root)
      @run_tests = opts[:run_tests] || !!ENV['TEST']
      @clean_on_startup = true
      @document_root = opts[:document_root] || 'build'
      if opts.key?(:clean_on_startup)
        @clean_on_startup = opts[:clean_on_startup]
      else
        @clean_on_startup = true
      end
      @watch_dirs = opts[:watch_dirs] || ['app', 'spec']
      setup_rakep_project
      start_watching
    end

    def document_root
      File.join(@root, @document_root)
    end

    def builder
      @builder ||= begin
        server = self
        Rack::Builder.new do
          use Rack::Lock, server.build_lock
          run Rack::File.new(server.document_root)
        end
      end
    end

    def after_build(&block)
      @after_build = block
    end

    def call(env)
      builder.call(env)
    end

    attr_reader :run_tests, :clean_on_startup, :project_name

    def setup_rakep_project
      project.pipelines.each do |pipeline|
        pipeline.rake_application = Rake.application
        pipeline.setup
      end
      project.invoke if clean_on_startup
    end

    def start_watching
      watcher_queue = Queue.new
      watcher_thread = Thread.new do
        listener = Listen.to(*@watch_dirs)
        listener.change(&build_proc)
        watcher_queue << listener
        listener.start # enter the run loop
      end
      watcher_thread.abort_on_exception = true

      puts "Watching #{watcher_queue.pop.directories}"
      start_testing if run_tests
    end

    def start_testing
      Thread.new do
        while true
          test_mutex.synchronize do
            test_resource.wait(test_mutex)
          end
          puts 'RUNNING TESTS'
          notification = if system('rake test')
            {
              app_name: project_name,
              title:    "#{project_name} error",
              text:     'JS test GREEN!'
            }
          else
            {
              app_name: project_name,
              title:    "#{project_name} error",
              text:     'JS test RED!'
            }
          end

          GNTP.notify(notification) rescue nil
        end
      end
    end

    def project
      @project ||= Rake::Pipeline::Project.new(File.join(@root, 'Assetfile'))
    end

    def build_lock
      @build_lock ||= Mutex.new
    end

    def build_proc
      @build_proc ||= create_build_proc
    end

  private
    def test_mutex
      @test_mutex ||= Mutex.new
    end

    def test_resource
      @test_resource ||= ConditionVariable.new
    end

    def run_after_build_callbacks

    end

    def create_build_proc
      lambda {|modified, added, removed|
        success = true
        build_lock.synchronize {
          puts 'FILE CHANGE'
          puts '  modified: ' + modified.join(', ') unless modified.empty?
          puts '  added: ' + added.join(', ') unless added.empty?
          puts '  removed: ' + removed.join(', ') unless removed.empty?
          start = Time.now
          if added.size > 0 || removed.size > 0
            puts "BUILD (CLEAN) #{start}"
            begin
              project.invoke
            rescue
              success = false
              puts "ERROR: #{$!.inspect}"
              GNTP.notify({
                :app_name => project_name,
                :title    => "#{project_name} error",
                :text     => "ERROR: #{$!.inspect}"
              }) rescue nil
            end
          else
            puts "BUILD #{start}"
            begin
              project.invoke
            rescue
              success = false
              puts "ERROR: #{$!.inspect}"
              GNTP.notify({
                :app_name => project_name,
                :title    => "#{project_name} error",
                :text     => "ERROR: #{$!.inspect}"
              }) rescue nil
            end
          end
          @after_build.call if @after_build
          puts "FINISHED #{Time.now.to_i - start.to_i} seconds"
        }
        # after UNLOCK
        if run_tests && success
          test_mutex.synchronize do
            test_resource.signal
          end
        end
      }
    end
  end
end
