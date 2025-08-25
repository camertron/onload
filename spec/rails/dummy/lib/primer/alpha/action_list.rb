module Primer
  module Alpha
    class ActionList
      def list
        "list ".upcase + Item.new.item
      end
    end
  end
end
