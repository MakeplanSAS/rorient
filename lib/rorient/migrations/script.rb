require 'find'
require 'benchmark'
require 'time'

module Rorient
  module Migrations
    # Script class
    class Script
      DELEGATED = [:name, :date, :time, :datetime, :type, :content, :path]
      attr_reader(*DELEGATED)

      def initialize(file)
        @file = file

        DELEGATED.each do |method|
          # instance_variable_set("@#{method}", DateTime.parse(file.send(method).to_s).iso8601) if method == :datetime
          instance_variable_set("@#{method}", file.send(method))
        end
      end

      def execute(db)
        puts statements(@type)
        @database = db
        return false unless new?
        driver = @database.driver
        puts driver
        begin
          # puts Rorient::Batch.new(statements: statements(@type)).generate_hash
          driver.batch.execute(Rorient::Batch.new(statements: statements(@type)).generate_hash)
        rescue
          puts "[-] Error while executing #{@type} #{@name} !"
          puts "    Info: #{self}"
          raise
        else
          true & on_success
        end
      end

      def unexecute(db)
        @database = db
        @type = "rollback"
        driver = @database.driver
        begin
          driver.batch.execute(Rorient::Batch.new(statements: statements(@type)).generate_hash)
        rescue
          puts "[-] Error while executing rollback #{@name} !"
          puts "    Info: #{self}"
          raise
        else
          true & on_success
        end

      end

      def self.find(database, type)
        files = []

        Find.find(Dir.pwd) do |path|
          file = Rorient::Migrations::File.new(path, database, type)

          raise "Duplicate time for #{type}s: #{files.find { |f| f == file }}, #{file}" if
          file.valid? && files.include?(file)

          files << file if file.valid?
        end

        files.sort_by(&:datetime).map { |file| new(file) }
      end

      def statements(statement_type=nil)
        separator = Rorient::Migrations::Config.options[:separator]
        if separator
          statements = @content.split(separator)
          statements.collect!(&:strip)
          statements.reject(&:empty?)
          if (statements & ["--#{statement_type}", "--end-#{statement_type}"]).any?
            begin_at = statements.index("--#{statement_type}")+1
            end_at = statements.index("--end-#{statement_type}")-1
            statements[begin_at..end_at] 
          else
            statements
          end
        else
          [content]
        end
      end

      def to_s
        "#{@type.capitalize} `#{@path}` for `#{@file.database}` database"
      end

      private

      def new?
        history = @database.history
        # If migrations table is empty
        puts @database.driver.query.execute(query_text: URI.encode("SELECT FROM #{history} LIMIT 1"))
        if @database.driver.query.execute(query_text: URI.encode("SELECT FROM #{history} LIMIT 1"))[:result].empty?
          true
        else
          last = @database.driver.query.execute(query_text: URI.encode("SELECT FROM #{history} WHERE type = '#{@type}' ORDER BY time DESC LIMIT 1"))[:result].first
          puts last
          is_new = @database.driver.query.execute(query_text: URI.encode("SELECT FROM #{history} WHERE time = #{@datetime} AND type = '#{@type}'"))[:result].count == 0
          puts is_new
          puts "[!] #{self} datetime BEFORE last one executed !" if is_new && last && last[:time] > @datetime
          
          is_new
        end
      end

      def on_success
        puts "[+] Successfully executed #{@type}, name: #{@name}"
        puts "    Info: #{self}"
        puts "    Benchmark: #{@benchmark}"
        
        history = @database.history.to_s
        case @type 
        when "migration"
          puts "[+] Migrating history table"
          @database.driver.document.create("@class": history, time: @datetime, name: @name, type: @type, executed: Time.now.utc.iso8601(3))
        when "rollback"
          puts "[+] Rolling back history table"
          migration_record = @database.driver.query.execute(query_text: URI.encode("SELECT FROM #{history} WHERE type = 'migration' AND time = #{@datetime.to_s} ORDER BY time DESC LIMIT 1"))[:result].first
          @database.driver.document.delete(rid: Rorient::Rid.new(rid_obj: migration_record[:@rid]).rid) if migration_record 
        end
      end
    end
  end
end
