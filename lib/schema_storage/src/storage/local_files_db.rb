require 'json'

class LocalFilesDb

  attr_accessor :mutexes, :location, :cache

  def initialize(file_path)
    @mutexes = {}
    @location = file_path
  end

  def get_mutex(table)
    @mutexes[table] = Mutex.new if @mutexes[table].nil?
    @mutexes[table]
  end

  def file_load(table)
    file_name = "#{@location}/#{table.downcase}.json"
    File.exist?(file_name) ? JSON.parse(File.read(file_name)) : {}
  end

  def file_write(table, persist_objs)
    file_name = "#{@location}/#{table.downcase}.json"
    Dir.mkdir(@location) unless Dir.exist?(@location)
    File.write(file_name, persist_objs.to_json)
  end

  def load(table)
    mutex = get_mutex(table)
    mutex.synchronize do
      file_load(table)
    end
  end

  def persist(table, items)
    mutex = get_mutex(table)
    mutex.synchronize do
      file_write(table, items)
    end
  end

end