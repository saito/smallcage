source "https://rubygems.org"

gem 'syck', :platforms => :ruby_20

group :development, :test do
  gem 'rspec', '~> 3.3.0'
end

group :development do
  gem 'rake'

  platforms :ruby_19, :ruby_20 do
    gem 'simplecov', :require => false
    gem 'awesome_print'

    if RUBY_VERSION >= '1.9.3'
      gem 'rubocop', '~> 0.33.0', :require => false
      gem 'guard', :require => false
      gem 'guard-rspec', :require => false
    end
  end
end
