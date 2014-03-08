source "https://rubygems.org"

gem 'syck', :platforms => :ruby_20

group :development, :test do
  gem 'rspec'
end

group :development do
  gem 'rake'

  platforms :ruby_19, :ruby_20 do
    gem 'simplecov', :require => false
    gem 'rubocop', :require => false

    if RUBY_VERSION >= '1.9.3'
      gem 'guard', :require => false
      gem 'guard-rspec', :require => false
    end
  end
end
