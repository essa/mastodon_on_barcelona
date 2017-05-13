
require 'yaml'

module MastodonOnBarcelon
  class Resources
    def self.load(cli)
      new(cli)
    end

    attr_reader :cli, :path, :values

    def initialize(cli)
      @cli = cli
      @path = 'resources.yaml'
      load
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      @values[key] = value
    end

    def load
      @values = YAML::load(File::open(path).read).deep_symbolize_keys
      self
    rescue Errno::ENOENT
      @values = {}
      self
    rescue
      cli.say $!.class
      cli.say $!
      cli.say "can't load #{path}"
      exit(1)
    end

    def add(h)
      @values.merge!(h)
    end

    def save
      File::open(path, 'w') do |f| 
        f.puts values.deep_stringify_keys.to_yaml
      end
    end
  end
end
