require 'loadr/formatters/base_formatter'

module Loadr
  module Formatters
    class TextFormatter < BaseFormatter
      def report(node=root_node, indent=0)
        return if node.total_duration < duration_threshold
        node_report = "#{' '*indent}#{node.path} - %.4f (%.4f)" % [node.total_duration, node.self_duration]
        child_reports = node.children.map{|c| report(c, indent+2) }.compact
        [node_report, *child_reports].join("\n")
      end
    end
  end
end
