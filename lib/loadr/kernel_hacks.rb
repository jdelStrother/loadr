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
