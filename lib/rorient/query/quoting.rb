# reference: ActiveRecord::ConnectionAdapter::Quoting
require 'yaml'
require 'bigdecimal'

module Rorient::Query::Quoting
  # Quotes the value rather than column name to help prevent
  # {SQL injection attacks}[http://en.wikipedia.org/wiki/SQL_injection].
  def self.quote(value, column = nil)
    case value
    when String
      value = value.to_s
      return "'#{quote_string(value)}'" unless column

      case column.type
      when :integer then value.to_i.to_s
      when :float then value.to_f.to_s
      else
        "'#{quote_string(value)}'"
      end

    when true, false
      if column && column.type == :integer
        value ? '1' : '0'
      else
        value ? quoted_true : quoted_false
      end
      # BigDecimals need to be put in a non-normalized form and quoted.
    when nil        then "NULL"
    when BigDecimal then value.to_s('F')
    when Numeric    then value.to_s
    when Date, Time then "'#{quoted_date(value)}'"
    when Symbol     then "'#{quote_string(value.to_s)}'"
    when Class      then "'#{value.to_s}'"
    else
      "'#{quote_string(YAML.dump(value))}'"
    end
  end

  # Quotes a string, escaping any ' (single quote) and \ (backslash)
  # characters as SQL escape
  def self.quote_string(s)
    s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
  end

  # alias to module function quote_string
  def self.escape(s)
    quote_string(s)
  end

  # Quotes the column name. Defaults to no quoting.
  def self.quote_column_name(column_name)
    column_name
  end

  # Quotes the table name. Defaults to column name quoting.
  def self.quote_table_name(table_name)
    quote_column_name(table_name)
  end

  # Override to return the quoted table name for assignment. Defaults to
  # table quoting.
  def self.quote_table_name_for_assignment(table, attr)
    quote_table_name("#{table}.#{attr}")
  end

  def self.quoted_true
    "'t'"
  end

  def self.quoted_false
    "'f'"
  end

  def self.quoted_date(value)
    if value.is_a?(Time)
      # ToDo: getutc support
      value = value.getlocal
    end
    value.strftime("%Y-%m-%d %H:%M:%S") 
  end
end
