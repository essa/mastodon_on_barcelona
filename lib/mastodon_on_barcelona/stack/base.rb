#!/usr/bin/env ruby

require 'thor'
require 'json'
require 'aws-sdk'
require 'jbuilder'
require './lib/mastodon_on_barcelona/cf_executor'

module MastodonOnBarcelon
  module Stack

    class Base
      attr_reader :name, :network_attributes, :config, :resources
      def initialize(name, config, network_attributes, resources)
        @name = name
        @config = config
        @network_attributes = network_attributes
        @resources = resources
      end

      def resource_name
        "mstdn-#{@name}"
      end

      def stack_name
        resource_name
      end

      def target!
        build.target!
      end

      private

      def ref(r)
        {"Ref" => r}
      end

      def get_attr(*path)
        {"Fn::GetAtt" => path}
      end

    end
  end
end

