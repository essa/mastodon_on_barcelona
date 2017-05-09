#!/usr/bin/env ruby

require 'json'
require 'aws-sdk'
require 'jbuilder'

module MastodonOnBarcelon
  module Stack
    class DB < Base

      def resource_name
        "#{super}-db"
      end

      def build
        Jbuilder.new do |j|
          j.Description description
          j.AWSTemplateFormatVersion "2010-09-09"

          j.Parameters do |jj|
            build_parameters(jj)
          end

          j.Resources do |jj|
            jj.DBSecurityGroup do |jjj| 
              db_security_group(jjj)
            end
            jj.DBSubnetGroup do |jjj| 
              db_subnet_group(jjj)
            end
            jj.DBInstance do |jjj| 
              db_instance(jjj)
            end
            jj.MediaBucket do |jjj| 
              media_bucket(jjj)
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
        j.MediaBucket do |jj| 
          jj.Description "S3 bucket name for storing media"
          jj.Value ref("MediaBucket")
        end
        j.DBEndPoint do |jj| 
          jj.Description "The end point of DB instance"
          jj.Value get_attr("DBInstance", "Endpoint.Address")
        end
      end

      private

      def db_security_group(j)
        subnet_cidrs = network_attributes[:subnet_cidrs]
        ingress = subnet_cidrs.map do |cidr|
          [
            {
              "IpProtocol" => "tcp",
              "FromPort" => 5432,
              "ToPort" => 5432,
              "CidrIp" => cidr
            },
            {
              "IpProtocol" => "tcp",
              "FromPort" => 6379,
              "ToPort" => 6379,
              "CidrIp" => cidr
            },
          ]
        end.flatten
        j.Type "AWS::EC2::SecurityGroup"
        j.Properties do
          j.GroupDescription "DB security group for mastodon #{resource_name}"
          j.VpcId network_attributes[:vpc_id]
          j.SecurityGroupIngress ingress
        end
      end

      def db_subnet_group(j)
        j.Type "AWS::RDS::DBSubnetGroup"
        j.Properties do
          j.DBSubnetGroupDescription "db subnet group for mastodon #{resource_name}"
          j.SubnetIds network_attributes[:subnet_ids]
        end
      end

      def db_instance(j)
        j.Type "AWS::RDS::DBInstance"
        j.Properties do
          j.AllocatedStorage options[:allocated_strage]
          j.AllowMajorVersionUpgrade true
          j.AutoMinorVersionUpgrade true
          j.Engine "postgres"
          j.DBInstanceClass options[:db_instance_class]
          j.DBInstanceIdentifier resource_name
          j.DBName 'mstdn'
          j.MasterUsername options[:db_user]
          j.MasterUserPassword options[:db_password]
          j.MultiAZ options[:db_multi_az]
          j.VPCSecurityGroups [
            ref("DBSecurityGroup")
          ]
          j.DBSubnetGroupName ref("DBSubnetGroup")
          j.StorageType "gp2"
        end
      end

      def media_bucket(j)
        j.Type "AWS::S3::Bucket"
      end

      def description
        "AWS CloudFormation for Barcelona #{resource_name}"
      end
    end
  end
end

