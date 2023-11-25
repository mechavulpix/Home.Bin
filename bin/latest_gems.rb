#!/usr/bin/env ruby
#
# Latest Gems
#
# Parse the local Gemfile and display the latest versions if updates are
# available

require "bundler"

def main
  return if invalid_gemfile?

  gem_details = parse_gem_details
  display_available_updates(gem_details)
end

def invalid_gemfile?
  unless File.exist? "Gemfile"
    STDERR.puts "No Gemfile found...  Exiting."
    return true
  end
end

def parse_gem_details
  definition = Bundler::Definition.build('Gemfile', '', {})
  
  gem_details = []
  definition.dependencies.each do |dependency|
    gem_details << GemDetail.from_dependency(dependency)
  end

  return gem_details
end

def display_available_updates(gem_details)
  if gem_details.empty?
    puts "Gemfile contains no gems"
    exit
  end

  if gem_details.map(&:latest?).reduce(:&)
    puts "All gems are up to date!"
    exit
  end
  
  gem_details.each do |gem_detail|
    puts gem_detail.full_details unless gem_detail.latest?
  end
end

class GemDetail
  GEM_SEARCH_COMMAND = "gem search %s -eraq"
  GEM_VERSIONS_REGEX = /\(([^\)]*)\)/

  attr_reader :name, :version

  def initialize(name:, version:)
    @name = name
    @version = version
  end

  def latest
    @latest ||= fetch_latest
  end

  def latest?
    latest.match?(version)
  end

  def full_details
    "* #{name}: #{version} -> #{latest}"
  end

  def self.from_dependency(dependency)
    name = dependency.name
    version = get_dependency_version_number(dependency)
    GemDetail.new(name: name, version: version)
  end

  private

  def fetch_latest
    raw_latest = `#{sprintf(GEM_SEARCH_COMMAND, name)}`
    return raw_latest[GEM_VERSIONS_REGEX, 1].split(",").first
  end

  def self.get_dependency_version_number(dependency)
    dependency.requirement.requirements.last.last.version
  end
end

if __FILE__ == $0
  main
end
