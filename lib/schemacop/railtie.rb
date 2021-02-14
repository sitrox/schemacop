module Schemacop
  class Railtie < Rails::Railtie
    initializer 'schemacop' do
      # Load global schemas
      unless Rails.env.development?
        V3::GlobalContext.eager_load!
      end

      # Tell Zeitwerk to ignore the files in our load path
      if defined?(Rails) && defined?(Zeitwerk) && Rails.autoloaders.zeitwerk_enabled?
        Schemacop.load_paths.each do |load_path|
          Rails.autoloaders.main.ignore(Rails.root.join(load_path))
        end
      end
    end
  end
end
