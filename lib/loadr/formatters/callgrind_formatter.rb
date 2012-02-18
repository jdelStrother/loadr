require 'loadr/formatters/base_formatter'

module Loadr
  module Formatters
    class CallgrindFormatter < BaseFormatter
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
  end
end
