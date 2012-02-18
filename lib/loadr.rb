require 'set'
require "loadr/version"
require 'loadr/loaded_node'
require 'loadr/formatters/text_formatter'
require 'loadr/formatters/callgrind_formatter'
require 'loadr/kernel_hacks'

module Loadr
  def root_node
    @root_node ||= LoadedNode.new(__FILE__).tap{|n| n.first_load = true}
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
      node = LoadedNode.new(path, caller_path, @load_stack[-1])
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



if __FILE__==$0
  path = File.expand_path(ARGV[0], Dir.pwd) # using full path so that LoadedNode#full_path gets expanded properly
  Loadr.monitor(path, __FILE__) do
    load path
  end
end

at_exit do
  Loadr.root_node.mark_end!
  puts Loadr::Formatters::TextFormatter.new(Loadr.root_node).report
  Loadr::Formatters::CallgrindFormatter.new(Loadr.root_node).report
end

