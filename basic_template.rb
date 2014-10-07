# helpers
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
    exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
      return exe if File.executable? exe
    end
  end
  return nil
end

def ask_wizard(question)
  ask "\033[1m\033[36m" + ("option").rjust(10) + "\033[1m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
    when "yes", "y"
      true
    when "no", "n"
      false
    else
      yes_wizard?(question)
  end
end
# End of helpers ---->

# .rvmrc
rvmrc_detected = false
create_rvmrc_specific = false
if File.exist?('.rvmrc')
  rvmrc_file = File.read('.rvmrc')
  rvmrc_detected = rvmrc_file.include? app_name
end

if File.exist?('.ruby-gemset')
  rvmrc_file = File.read('.ruby-gemset')
  rvmrc_detected = rvmrc_file.include? app_name
end
unless rvmrc_detected
  create_rvmrc_specific = yes_wizard? 'Use or create a project-specific rvm gemset ?'
end
if create_rvmrc_specific
  if which("rvm")
    say "recipe creating project-specific rvm gemset and .rvmrc"
    if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
      begin
        gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')
        ENV['GEM_PATH'] = "#{gems_path}:#{gems_path}@global"
        require 'rvm'
        RVM.use_from_path! File.dirname(File.dirname(__FILE__))
      rescue LoadError
        raise "RVM gem is currently unavailable."
      end
    end
    say "creating RVM gemset '#{app_name}'"
    RVM.gemset_create app_name
    say "switching to gemset '#{app_name}'"
    # RVM.gemset_use! requires rvm version 1.11.3.5 or newer
    rvm_spec = Gem::Specification.respond_to?(:find_by_name) ? Gem::Specification.find_by_name("rvm") : Gem.source_index.find_name("rvm").last
      unless rvm_spec.version > Gem::Version.create('1.11.3.4')
        say "rvm gem version: #{rvm_spec.version}"
        raise "Please update rvm gem to 1.11.3.5 or newer"
      end
    begin
      RVM.gemset_use! app_name
    rescue => e
      say "rvm failure: unable to use gemset #{app_name}, reason: #{e}"
      raise
    end
    File.exist?('.ruby-version') ? say(".ruby-version file already exists") : create_file('.ruby-version', "#{RUBY_VERSION}\n")
    File.exist?('.ruby-gemset') ? say(".ruby-gemset file already exists") : create_file('.ruby-gemset', "#{app_name}\n")
  else
    say "WARNING! RVM does not appear to be available."
  end
end
# End of rvmrc ----->

# group development test 
gem_group :development, :test do
  gem 'rspec-rails', '~> 3.0.0'
end

# group development
gem_group :development do
  gem 'brakeman', :require => false
end
run 'bundle install'
generate 'rspec:install' unless File.exists?('.rspec')