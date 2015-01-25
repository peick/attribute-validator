#
# Cookbook Name:: attribute-validator-ng
# Recipe:: converge-time-check
#
# Copyright (C) 2013 Michael Peick
#

ruby_block 'convergence time attribute validation' do
  block do
    Chef::Attribute::Validate.validate(
      node['attribute-validator-ng']['rules'],
      node['attribute-validator-ng']['fail-action'],
      node)
  end
end
