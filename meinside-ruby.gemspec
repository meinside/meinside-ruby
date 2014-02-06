# last update: 2014.02.06.

Gem::Specification.new do |s|
  # version/date
  s.version     = '0.0.1'
  s.date        = '2014-02-06'

  # project info
  s.name        = 'meinside-ruby'
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'my ruby scripts and libraries'
  s.description = 'my ruby scripts and libraries for daily use'
  s.files       = Dir['lib/*.rb'] + Dir['lib/test/*.rb'] + Dir['bin/*']
  s.executables = Dir['bin/*'].map{|x| File.basename(x)}
  s.license     = 'MIT'

  # dependencies
  s.add_dependency('aws-sdk', '~> 0')
  s.add_dependency('coderay', '~> 0')
  s.add_dependency('dropbox-sdk', '~> 0')
  s.add_dependency('highline', '~> 0')
  s.add_dependency('json', '~> 0')
  s.add_dependency('mime', '~> 0')
  s.add_dependency('mimemagic', '~> 0')
  s.add_dependency('mysql', '~> 0')
  s.add_dependency('net-scp', '~> 0')
  s.add_dependency('net-sftp', '~> 0')
  s.add_dependency('net-ssh', '~> 0')
  s.add_dependency('ruby-gmail', '~> 0')
  s.add_dependency('ruby-hmac', '~> 0')
  s.add_dependency('sqlite3', '~> 0')
  s.add_dependency('thor', '~> 0')

  # profile
  s.authors     = ['Sungjin Han']
  s.email       = 'meinside@gmail.com'
  s.homepage    = 'http://github.com/meinside/meinside-ruby'
end

