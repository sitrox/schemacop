module Schemacop
  class Railtie < Rails::Railtie
    initializer 'schemacop' do
      # Load global schemas
      unless Rails.env.development?
        V3::GlobalContext.reload!
      end
    end
  end
end
