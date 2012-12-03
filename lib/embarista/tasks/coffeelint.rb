module CoffeeLintHelper
  extend Rake::DSL

  def self.coffeelint(cmd_args)
    tool = 'coffeelint'
    cmd_args = cmd_args || ''

    node = which('node')
    if node.nil?
      puts "Could not find node in your path."
      return
    end

    npm = which('npm')
    if npm.nil?
      puts "Could not find npm in your path."
      return
    end

    coffeelint = which('coffeelint')

    if coffeelint
      sh "coffeelint #{cmd_args}"

    else
      if !File.directory?("node_modules/#{tool}")
        sh "\"#{npm}\" install #{tool}"
      end

      sh "\"#{node}\" node_modules/#{tool}/bin/#{tool} #{cmd_args}"
    end
  end

  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        sep = File::ALT_SEPARATOR || File::SEPARATOR
        exe = "#{path}#{sep}#{cmd}#{ext}"
        return exe if File.executable? exe
      }
    end
    return nil
  end
end

desc 'run coffeelint'
task :coffeelint do
  CoffeeLintHelper.coffeelint '-q -f config/coffeelint.json -r app'
end
