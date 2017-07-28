module Gitlab
  module Git
    class Branch < Ref
      def self.find(repository,name)
        repository.branches.find { |branch| branch.name == name }
      end
    end
  end
end
