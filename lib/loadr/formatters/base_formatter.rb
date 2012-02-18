module Loadr
  module Formatters
    class BaseFormatter
      attr_accessor :root_node, :duration_threshold
      def initialize(root_node, duration_threshold=0.001)
        self.root_node = root_node
        self.duration_threshold = duration_threshold
      end
    end
  end
end
