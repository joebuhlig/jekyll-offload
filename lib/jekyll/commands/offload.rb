module Jekyll
  module Commands
    class Offload < Jekyll::Command
      def self.init_with_program(prog)
        prog.command(:offload) do |c|
          c.syntax "offload [options]"
          c.description 'Move files to S3 and delete locally.'

          c.action do |args, options|
            JekyllOffload.offload()
          end
        end
      end
    end
  end
end

