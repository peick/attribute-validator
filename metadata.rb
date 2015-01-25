name             'attribute-validator-ng'
maintainer       'Michael Peick'
maintainer_email 'chef@n-pq.de'
license          'BSD (3-clause)'
description      'Enforces attribute validation rules.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.4.0'

recipe 'compile-time-check', 'Enforces attribute validation rules at compile time'
recipe 'converge-time-check', 'Enforces attribute validation rules at convergence time'
recipe 'default', 'Runs converge-time-check'


