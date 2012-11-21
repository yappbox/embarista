module Embarista
  module DigestHelper
    extend self

    def digest_and_copy_file(filename, target_dir = 'tmp')
      file = Pathname.new(filename)
      target_dir = Pathname.new(target_dir)

      md5 = Digest::MD5.file(file).hexdigest
      ext = file.extname
      dirname = file.dirname
      name_without_ext = file.basename.to_s.gsub(/#{ext}$/,'')

      new_filename = "#{name_without_ext}-#{md5}#{ext}"
      target_dir_with_path = target_dir + dirname
      target_full_path = target_dir_with_path + new_filename

      mkdir_p(target_dir_with_path)
      cp(filename, target_full_path)

      return dirname + new_filename
    end

    def digest_directory(origin, target)
      origin = Pathname.new(origin).expand_path
      target = Pathname.new(target).expand_path

      target_base_dir = target + origin.basename

      rm_rf target_base_dir
      mkdir_p target_base_dir

      cd(origin) do
        files = Dir['**/**.*'].reject { |file| File.directory?(file) }.reject { |file| file =~ /manifest*\.yml/ }

        manifest_hash = files.each_with_object({}) do |file, manifest|
          manifest[file.to_s] = digest_and_copy_file(file, target_base_dir).to_s
        end

        manifest_hash = ManifestHelper.prefix_manifest('/', manifest_hash)

        open('manifest.yml', 'w') do |file|
          YAML.dump(manifest_hash, file)
        end

        cp('manifest.yml', target_base_dir + 'manifest-latest.yml')

        return manifest_hash
      end
    end
  end
end
