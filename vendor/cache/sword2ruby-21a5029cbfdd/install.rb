require 'fileutils'

# build path to SWORD config file
sword_config = File.dirname(__FILE__) + '/../../../config/sword.yml'

# copy over template SWORD config if not already there
FileUtils.cp File.dirname(__FILE__) + '/config/sword.yml', sword_config unless File.exists?(sword_config)

# output readme file
puts IO.read(File.join(File.dirname(__FILE__), 'README'))
