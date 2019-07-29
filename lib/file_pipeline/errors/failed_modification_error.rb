# frozen_string_literal: true

module FilePipeline
  module Errors
    # Error class for exceptions that are raised when a a FileOperation in a
    # Pipeline returns failure.
    class FailedModificationError < StandardError
      # The file opration that caused the error.
      attr_reader :info

      def initialize(msg = nil, info: nil)
        @info = info
        if info.respond_to?(:operation) && info.respond_to?(:log)
          msg ||= "#{@info.operation&.name} with options"\
                  " #{@info.operation&.options} failed, log: #{@info.log}"
        else
          msg ||= 'Operation failed' unless info
        end
        super msg
      end
    end
  end
end
