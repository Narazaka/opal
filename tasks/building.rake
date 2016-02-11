require 'opal/version'

desc <<-DESC
Build *corelib* and *stdlib* to "build/"

You can restrict the file list with the FILES env var (comma separated)
and the destination dir with the DIR env var.

Example: rake dist DIR=/tmp/foo FILES='opal.rb,base64.rb'
Example: rake dist DIR=cdn/opal/#{Opal::VERSION}
Example: rake dist DIR=cdn/opal/master
DESC
task :dist do
  require 'opal/util'
  require 'opal/sprockets/environment'

  Opal::Processor.arity_check_enabled = false
  Opal::Processor.const_missing_enabled = false
  Opal::Processor.dynamic_require_severity = :warning
  env = Opal::Environment.new

  build_dir = ENV['DIR'] || 'build'
  files     = ENV['FILES'] ? ENV['FILES'].split(',') :
              Dir['{opal,stdlib}/*.rb'].map { |lib| File.basename(lib, '.rb') }

  Dir.mkdir build_dir unless File.directory? build_dir
  width = files.map(&:size).max

  files.each do |lib|
    print "* building #{lib}...".ljust(width+'* building ... '.size)
    $stdout.flush

    src = env[lib].to_s
    min = Opal::Util.uglify src
    gzp = Opal::Util.gzip min

    File.open("#{build_dir}/#{lib}.js", 'w+')        { |f| f << src }
    File.open("#{build_dir}/#{lib}.min.js", 'w+')    { |f| f << min } if min
    File.open("#{build_dir}/#{lib}.min.js.gz", 'w+') { |f| f << gzp } if gzp

    print "done. ("
    print "development: #{('%.2f' % (src.size/1000.0)).rjust(6)}KB"
    print  ", minified: #{('%.2f' % (min.size/1000.0)).rjust(6)}KB" if min
    print   ", gzipped: #{('%.2f' % (gzp.size/1000.0)).rjust(6)}KB" if gzp
    puts  ")."
  end
end

desc <<-DESC
Build *corelib* and *stdlib* into one file "build/opal_all.js"

You can restrict the file list with the FILES env var (comma separated),
the destination dir with the DIR env var
and the Description file name with the NAME env var.

Example: rake dist DIR=/tmp/foo FILES='opal.rb,base64.rb' NAME='opal_with_b64'
Example: rake dist DIR=cdn/opal/#{Opal::VERSION}
Example: rake dist DIR=cdn/opal/master
DESC
task :onedist do
  require 'opal/util'
  require 'opal/sprockets/environment'

  Opal::Processor.arity_check_enabled = false
  Opal::Processor.const_missing_enabled = false
  Opal::Processor.dynamic_require_severity = :warning
  env = Opal::Environment.new

  build_dir = ENV['DIR'] || 'build'
  files     = ENV['FILES'] ? ENV['FILES'].split(',') :
              Dir['{opal,stdlib}/*.rb'].map { |lib| File.basename(lib, '.rb') }
  onelib    = ENV['NAME'] || "opal_all"

  Dir.mkdir build_dir unless File.directory? build_dir
  width = files.map(&:size).max

  puts "* building #{onelib}..."
  src = files.map do |lib|
    print "* building #{lib}...".ljust(width+'* building ... '.size)
    $stdout.flush

    _src = env[lib].to_s

    print "done. ("
    print "development: #{('%.2f' % (_src.size/1000.0)).rjust(6)}KB"
    puts  ")."

    _src
  end.join("\n") + "\nif (typeof(module) !== 'undefined') { module.exports = {Opal: Opal}; Opal.global = this; }\n"

  File.open("#{build_dir}/#{onelib}.js", 'w+')        { |f| f << src }
  puts "development: #{('%.2f' % (src.size/1000.0)).rjust(6)}KB"
  min = Opal::Util.uglify src
  File.open("#{build_dir}/#{onelib}.min.js", 'w+')    { |f| f << min } if min
  puts "   minified: #{('%.2f' % (min.size/1000.0)).rjust(6)}KB" if min
  gzp = Opal::Util.gzip min
  File.open("#{build_dir}/#{onelib}.min.js.gz", 'w+') { |f| f << gzp } if gzp
  puts "    gzipped: #{('%.2f' % (gzp.size/1000.0)).rjust(6)}KB" if gzp
  puts "done"
end

desc 'Rebuild grammar.rb for opal parser'
task :racc do
  debug_option = '--debug' if ENV['RACC_DEBUG']
  sh "racc #{debug_option} -l -o lib/opal/parser/grammar.rb lib/opal/parser/grammar.y"
end

desc 'Remove any generated file.'
task :clobber do
  rm_r './build'
end

