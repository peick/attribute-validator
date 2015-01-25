#
# Cookbook Name:: attribute-validator-ng
# Recipe:: compile-time-check
#
# Copyright (C) 2013 Michael Peick
#

Chef::Log.info('Running compile-time node attribute validations')

Chef::Attribute::Validator.validate(
  node['attribute-validator-ng']['rules'],
  node,
  node['attribute-validator-ng']['fail-action'])
