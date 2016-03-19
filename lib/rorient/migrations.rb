# Rorient::Migrations
#
module Rorient
  module Migrations

    autoload :Database, 'rorient/migrations/database'
    autoload :Config, 'rorient/migrations/config'
    autoload :File, 'rorient/migrations/file'
    autoload :Script, 'rorient/migrations/script'
    autoload :Migration, 'rorient/migrations/migration'
    autoload :Seed, 'rorient/migrations/seed'

    extend self

    def migrate
      databases(&:migrate)
    end

    def seed
      databases(&:seed)
    end

    def scripts
      Config.databases.each do |name, _config|
        Migration.find(name).each { |migration| puts migration }
        Seed.find(name).each      { |seed|      puts seed      }
      end
    end
  end
end
