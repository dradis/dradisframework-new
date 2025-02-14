# Rails 5.2 now loads the environment on all db rake tasks. Previously it did
# not for setup or create. This means if the db doesn't exist this code will
# fail. Technically we shouldn't communicate with AR during initializers so this
# is workaround.
# https://github.com/rails/rails/issues/32870

# Unless the DB is already migrated, do nothing

Rails.application.reloader.to_prepare do
  ActiveRecord::Base.lease_connection do
    if Configuration.table_exists? &&
      Configuration.paths_templates.exist? &&
      Mapping.table_exists?
      # ---------------------------------------------------------------- 3.1 Upload
      template_dir = Configuration.paths_templates_plugins
      # mappings table may not exist when migrating from an old OVA to a new one so we need this guard
      Dradis::Plugins::with_feature(:upload).each do |integration|
        integration.copy_samples(to: template_dir)
        integration.migrate_templates_to_mappings(from: template_dir) if !Rails.env.test?
      end

      # ---------------------------------------------------------------- 3.2 Export
      template_dir = Configuration.paths_templates_reports
      Dradis::Plugins::with_feature(:export).each do |plugin|
        plugin.copy_samples(to: template_dir)
      end
    end
  end
end
