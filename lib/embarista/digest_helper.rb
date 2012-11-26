module Embarista
  module DigestHelper
    include FileUtils
    extend self

    def digest_and_copy_file(filename, target_dir = 'tmp', version=nil)
      file = Pathname.new(filename)
      target_dir = Pathname.new(target_dir)

      md5 = Digest::MD5.file(file).hexdigest
      ext = file.extname
      dirname = file.dirname
      name_without_ext = file.basename.to_s.chomp(ext)

      version_suffix = "-#{version}" if version
      new_filename = "#{name_without_ext}#{version_suffix}-#{md5}#{ext}"
      target_dir_with_path = target_dir + dirname
      target_full_path = target_dir_with_path + new_filename

      mkdir_p(target_dir_with_path)
      cp(filename, target_full_path)

      return dirname + new_filename
    end

    def digest_directory(origin, target, version=nil)
      origin = Pathname.new(origin).expand_path
      target = Pathname.new(target).expand_path

      target_base_dir = target + origin.basename

      rm_rf target_base_dir
      mkdir_p target_base_dir

      cd(origin) do
        glob_pattern_with_symlink_support = "**{,/*/**}/*.*" # http://stackoverflow.com/questions/357754/can-i-traverse-symlinked-directories-in-ruby-with-a-glob
        files = Dir.glob(glob_pattern_with_symlink_support).reject { |file| File.directory?(file) }.reject { |file| file =~ /manifest*\.(yml|json)/ }

        manifest_hash = files.each_with_object({}) do |file, manifest|
          manifest[file.to_s] = digest_and_copy_file(file, target_base_dir, version).to_s
        end

        manifest_hash = ManifestHelper.prefix_manifest('/', manifest_hash)

        open('manifest.yml', 'w') do |file|
          YAML.dump(manifest_hash, file)
        end

        open('manifest.json', 'w') do |file|
          JSON.dump(manifest_hash, file)
        end

        cp('manifest.yml', target_base_dir + 'manifest-latest.yml')
        cp('manifest.json', target_base_dir + 'manifest-latest.json')

        return manifest_hash
      end
    end
  end
end
