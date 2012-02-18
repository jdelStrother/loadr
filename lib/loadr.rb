require "loadr/version"
require 'set'

module Loadr
  class Report
    attr_accessor :root_node, :duration_threshold
    def initialize(root_node, duration_threshold=0.001)
      self.root_node = root_node
      self.duration_threshold = duration_threshold
    end
  end
  class TextReport < Report
    def report(node=root_node, indent=0)
      return if node.total_duration < duration_threshold
      node_report = "#{' '*indent}#{node.path} - %.4f (%.4f)" % [node.total_duration, node.self_duration]
      child_reports = node.children.map{|c| report(c, indent+2) }.compact
      [node_report, *child_reports].join("\n")
    end
  end

  class CallgrindReport < Report
    def output
      @output ||= File.new('callgrind.out', 'w').tap do |f|
        f.write("events: loadtimes\n")
      end
    end
    def report(node=root_node)
      real_report(node)
      output.close
    end
  private
    def real_report(node)
      return if node.total_duration < duration_threshold

      output.write("\n")
      output.write(<<-EOF.gsub(/^\s*/,'')
        \nfl=#{node.full_path}
        fn=#{node.function}
        1 #{(node.self_duration*1000000).to_i}
        EOF
      )
      node.children.each do |child|
        output.write(<<-EOF.gsub(/^\s*/,'')
          cfl=#{child.full_path}
          cfn=#{child.function}
          calls=1 0
          1 #{(child.total_duration*1000000).to_i}
        EOF
        )
      end

      node.children.each{|c| real_report(c)}
    end
  end

  class LoadingNode
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

  def root_node
    @root_node ||= LoadingNode.new(__FILE__).tap{|n| n.first_load = true}
  end
  module_function :root_node

  def loaded_paths
    @loaded_paths ||= Set.new
  end
  module_function :loaded_paths

  def monitor(path, caller_path=nil)
    already_loaded = loaded_paths.include?(path)
    if ignore_duplicate_loads? && already_loaded
      return yield
    end

    begin
      @load_stack ||= [root_node]
      node = LoadingNode.new(path, caller_path, @load_stack[-1])
      node.first_load = !already_loaded
      @load_stack.push(node)

      result = yield
      result
    ensure
      node.mark_end!
      @load_stack.pop
    end
  end
  module_function :monitor

  def ignore_duplicate_loads?
    false
  end
  module_function :ignore_duplicate_loads?

end



module Kernel
  alias loadr_original_require require
  def loadr_patched_require(path)
    caller_path = caller[-1] ? caller[-1].split(':')[0] : __FILE__
    Loadr.monitor(path, caller_path) do
      loadr_original_require(path)
    end
  end
  alias require loadr_patched_require
end

if __FILE__==$0
  path = File.expand_path(ARGV[0], Dir.pwd) # using full path so that LoadingNode#full_path gets expanded properly
  Loadr.monitor(path, __FILE__) do
    load path
  end
end

at_exit do
  Loadr.root_node.mark_end!
  puts Loadr::TextReport.new(Loadr.root_node).report
  #Loadr::CallgrindReport.new(Loadr.root_node).report
end

