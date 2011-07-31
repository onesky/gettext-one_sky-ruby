module GetText
  module Onesky
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "gettext-one_sky/rails/tasks/gettext-one_sky.rake"
      end      
    end
  end
end
