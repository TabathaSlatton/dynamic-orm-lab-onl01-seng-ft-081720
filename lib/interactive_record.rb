require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'
class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "PRAGMA table_info('#{table_name}')"
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |column|
            column_names << column["name"]
        end
        column_names.compact
    end

    def self.accessors 
        self.column_names.each do |col_name|
        attr_accessor col_name.to_sym
        end
    end

    def initialize(options={})
        self.class.accessors if !self.id
        options.each do |property, value|
          self.send("#{property}=", value)
        end
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
          values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = <<-SQL
        INSERT INTO students (name, grade) 
        VALUES (?, ?)
        SQL
        DB[:conn].execute(sql, self.name, self.grade)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def table_name_for_insert
        self.class.table_name
    end

     def self.find_by(attribute)
        key = attribute.keys[0].to_s
        value = attribute.values[0]
        sql = "SELECT * FROM students WHERE #{key} = ?"
        student = DB[:conn].execute(sql, value)
    end
end