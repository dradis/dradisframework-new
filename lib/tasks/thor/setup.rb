# frozen_string_literal: true

class DradisTasks < Thor
  class Setup < Thor
    include Thor::Actions
    include Rails::Generators::Actions
    include ::Rails.application.config.dradis.thor_helper_module

    namespace 'dradis:setup'

    def self.source_root
      File.join(__dir__, '../templates')
    end

    desc 'configure', 'Creates the Dradis configuration files from their templates (see config/*.yml.template)'
    def configure
      # init the config files
      init_all = false
      Dir['config/*.template'].each do |template|
        config = File.join('config', File.basename(template, '.template'))
        if !(File.exist?(config))
          if (init_all)
            puts "Initilizing #{config}..."
            FileUtils.cp(template, config)
          else
            puts "The config file [#{template}] was found not to be ready to use."
            puts 'Do you want to initialize it? [y]es | [N]o | initialize [a]ll'
            response = STDIN.gets.chomp.downcase
            response = 'Y' if (response.empty? || !['y', 'n', 'a'].include?(response))

            if response == 'n'
              next
            else
              puts "Initilizing #{config}..."
              FileUtils.cp(template, config)
              if (response == 'a')
                init_all = true
              end
            end
          end
        end
      end
    end

    desc 'kit', 'Import files and projects from a specified Kit configuration file'
    method_option :file, required: true, type: :string, desc: 'full path to the Kit file to use.'
    def kit
      puts '** Importing kit...'
      KitImportJob.perform_now(options[:file], logger: default_logger)
      puts '[  DONE  ]'
    end

    desc 'welcome', 'adds initial content to the repo for demonstration purposes'
    def welcome
      # Before we import the Kit we need at least 1 user
      User.create!(email: 'adama@dradisframework.com').id
      invoke 'dradis:setup:kit', [], file: File.join(self.class.source_root, 'welcome')
    end
  end
end
