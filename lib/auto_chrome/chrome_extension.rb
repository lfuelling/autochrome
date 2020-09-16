require "digest"
require "json"
require "open3"

class AutoChrome::ChromeExtension
  attr_reader :path, :id, :key, :manifest, :version

  def initialize(crx_path)
    @path = crx_path

    puts "[---] Initializing #{path}..."

    # use open3 to suppress unzip warnings for unexpected crx headers
    json, _, _ = Open3.capture3('unzip', '-qc', @path, 'manifest.json')

    @manifest = JSON.parse(json, symbolize_names: true)

    if @manifest.dig(:key) != nil
      puts "[---] Got key from manifest!"
      @key = @manifest[:key]
      @id = Digest::SHA256.hexdigest(Base64.decode64(@key))[0...32].tr('0-9a-f', 'a-p')
    else
      puts "[---] Reading key from external file..."
      key_file = File.dirname(path) + "/" + File.basename(@path, ".crx") + ".pub"
      unless File.exists?(key_file)
        raise "No key file found for extension #{path}"
      end
      @key = File.read(key_file)
      @id = Digest::SHA256.hexdigest(key)[0...32].tr('0-9a-f', 'a-p')
      @manifest[:key] = Base64.encode64(@key).gsub(/\s/, '')
    end

    if @manifest.dig(:id) != nil
      @id = @manifest[:id]
    else
      if :id == nil || id.to_s.strip.empty?
        raise "No id found for extension #{path}!"
      else
        puts "[---] Got id '#{id}'"
      end
    end

    if @manifest.dig(:version) != nil
      @version = @manifest[:version]
    else
      if :version == nil
        raise "No version found for extension #{path}!"
      end
    end
  end
end
