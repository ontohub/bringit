module Bringit
  class RevList
    attr_reader :repository, :env

    ALLOWED_VARIABLES = %w[GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES].freeze

    def initialize(oldrev, newrev, repository:, env: nil)
      @repository = repository
      @env = env.presence || {}
      @args = ["git",
                "--git-dir=#{repository.path}",
                "rev-list",
                "--max-count=1",
                oldrev,
                "^#{newrev}"]
    end

    def execute
      Bringit::Popen.popen(@args, nil, parse_environment_variables)
    end

    def valid?
      environment_variables.all? do |(name, value)|
        value.to_s.start_with?(repository.path)
      end
    end

    private

    def parse_environment_variables
      return {} unless valid?

      environment_variables
    end

    def environment_variables
      @environment_variables ||= env.slice(*ALLOWED_VARIABLES).compact
    end
  end
end
