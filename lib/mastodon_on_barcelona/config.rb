
require 'yaml'

module MastodonOnBarcelon
  class Config
    def self.create(cli, options)
      new(cli).create(options)
    end

    def self.load(cli)
      new(cli).load
    end

    attr_reader :cli, :path, :values

    def initialize(cli)
      @cli = cli
      @path = 'config.yaml'
      @values = {}
    end

    def [](key)
      @values[:config][key]
    end

    def []=(key, value)
      @values[:config][key] = value
    end

    def create(options)
      if File::exists?(path)
        ans = cli.yes?('You already have configured once, existing config.yaml will be overwritten ok?')
        exit(1) unless ans
      end
      s = ERB.new(TEMPLATE).result(binding)
      File::open(path, 'w') do |f| 
        f.puts s
      end
      cli.say("config.yaml is created. This file is used by later subcommands. Please check and edit it if you think you need to")
    end

    def load
      @values = YAML::load(File::open(path).read).deep_symbolize_keys
      self
    rescue
      cli.say $!
      cli.say "can't load config.yaml. run config first"
      exit(1)
    end
    TEMPLATE =<<EOT
config:
  region: <%= options[:region] %>
  hostname: <%= options[:hostname] %>
  district_name: <%= options[:district_name] %>
  heritage_name: <%= options[:name] %>
  certificate_arn: <%= options[:certificate_arn] %>
  endpoint: <%= options[:endpoint] %>
  db:
    user: mastodon_admin
    password: <%= SecureRandom.hex %>
    allocated_storage: 5 # MB
    instance_class: db.t2.micro
    storage_type: gp2
    multi_az: false
  redis:
    cache_node_type: cache.t2.micro
    num_cache_nodes: 1
  mastodon_source:
    repository: https://github.com/essa/mastodon.git
    branch: barcelona
  ecs:
    instance_type: t2.small
    cluster_size: 2

EOT
  end
end
