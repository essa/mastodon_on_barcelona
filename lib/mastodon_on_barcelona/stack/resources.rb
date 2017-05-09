#!/usr/bin/env ruby

require 'json'
require 'aws-sdk'
require 'jbuilder'

module MastodonOnBarcelon
  module Stack
    class Resources < Base

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
            jj.AdminUser do |jjj| 
              admin_user(jjj)
            end
            jj.AdminUserAccessKey do |jjj| 
              admin_user_access_key(jjj)
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
          jj.Description "The end point of redis instance"
          jj.Value get_attr("RedisCluster", "RedisEndpoint.Address")
        end
        j.AwsAccessKeyId do |jj|
          jj.Description "access key for admin"
          jj.Value ref("AdminUserAccessKey")
        end
        j.AwsSecretAccessKey do |jj|
          jj.Description "secret access key for admin"
          jj.Value get_attr("AdminUserAccessKey", "SecretAccessKey")
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
        c = config[:redis]
        j.Type "AWS::ElastiCache::CacheCluster"
        j.Properties do
          j.ClusterName resource_name
          j.CacheNodeType c[:cache_node_type]
          j.Engine "redis"
          j.NumCacheNodes c[:num_cache_nodes]
          j.VpcSecurityGroupIds [ resources[:DBSecurityGroup]]
          j.CacheSubnetGroupName ref("RedisSubnetGroup")
        end
      end

      def admin_user(j)
        district_name = config[:district_name]
        heritage_name = config[:heritage_name]
        media_bucket_arn = "arn:aws:s3:::#{resources[:MediaBucket]}"
        j.Type "AWS::IAM::User"
        j.Properties do
          j.UserName admin_user_name
          j.Policies [
            {
              "PolicyName" => "FullAccessToMedia#{district_name}#{heritage_name}",
              "PolicyDocument" => {
                "Version" => "2012-10-17",
                "Statement" => [
                  {
                    "Effect" => "Allow",
                    "Action" => [
                      "S3:*"
                    ],
                    "Resource" => [
                      media_bucket_arn,
                      "#{media_bucket_arn}/*"
                    ]
                  }
                ]
              }
            }
          ]
        end
      end

      def admin_user_access_key(j)
        j.Type "AWS::IAM::AccessKey"
        j.Properties do
          j.UserName admin_user_name
        end
      end

      def description
        "AWS CloudFormation for Barcelona #{resource_name}"
      end

      def admin_user_name
        "admin-#{config[:district_name]}-#{config[:heritage_name]}"
      end
    end
  end
end

