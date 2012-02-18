module Loadr
  class LoadedNode
    attr_accessor :path, :start_time, :end_time, :children, :parent, :first_load
    def initialize(path, loaded_from=nil, parent=nil)
      @path = path
      @loaded_from=loaded_from
      @start_time = Time.now
      @children = []
      if parent
        @parent = parent
        parent.children << self
      end
    end
    def mark_end!
      @end_time = Time.now
    end
    def total_duration
      @end_time - @start_time
    end
    def self_duration
      child_duration = children.inject(0){|m,child| m+=child.total_duration; m}
      total_duration - child_duration
    end
    def full_path
      filename = path.sub(/(?:\.rb)?$/, '.rb')
      load_paths = $LOAD_PATH.dup
      if filename=~%r{^(?:\.|/)} and @loaded_from
        # relative path, resolve relative to the calling path
        load_paths.unshift(File.dirname(@loaded_from))
      end
      load_paths.each do |dir|
        full_path = File.expand_path(filename, dir)
        return full_path if File.exist?(full_path)
      end
      "?/#{filename}"
    end
    def function
      "require('#{path}')"
    end
  end
end
