#!/usr/bin/env ruby

require 'json'
require 'aws-sdk'
require 'jbuilder'

module MastodonOnBarcelon
  module Stack
    class Resources

      def build
        Jbuilder.new do |j|
          j.Description description
          j.AWSTemplateFormatVersion "2010-09-09"

          j.Parameters do |jj|
            build_parameters(jj)
          end

          j.Resources do |jj|
            jj.RedisSubnetGroup do |jjj| 
              redis_subnet_group(jjj)
            end
            jj.RedisCluster do |jjj| 
              redis_cluster(jjj)
            end
          end

          j.Outputs do |json|
            build_outputs(json)
          end
        end
      end

      def build_parameters(json)
      end

      def build_outputs(j)
        j.RedisEndPoint do |jj| 
          jj.Description "The end point of DB instance"
          jj.Value get_attr("RedisCluster", "RedisEndpoint.Address")
        end
      end

      def target!
        build.target!
      end

      private

      def redis_subnet_group(j)
        j.Type "AWS::ElastiCache::SubnetGroup"
        j.Properties do
          j.CacheSubnetGroupName resource_name
          j.SubnetIds network_attributes[:subnet_ids]
          j.Description "redis subnet group for mastodon #{resource_name}"
        end
      end

      def redis_cluster(j)
        j.Type "AWS::ElastiCache::CacheCluster"
        j.Properties do
          j.ClusterName resource_name
          j.CacheNodeType "cache.t2.micro"
          j.Engine "redis"
          j.NumCacheNodes "1"
          j.VpcSecurityGroupIds [ ref("DBSecurityGroup")]
          j.CacheSubnetGroupName ref("RedisSubnetGroup")
        end
      end

      def description
        "AWS CloudFormation for Barcelona #{resource_name}"
      end
    end
  end
end

