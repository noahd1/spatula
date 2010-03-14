module Spatula
  # TODO: Set REMOTE_CHEF_PATH using value for file_cache_path
  REMOTE_CHEF_PATH = "/tmp/chef-solo" # Where to find upstream cookbooks

  class Cook
    def self.run(*args)
      new(*args).run
    end

    def initialize(server, node, port=22)
      @server = server
      @node = node
      @port = port
    end

    def run
      Dir["**/*.rb"].each do |recipe|
        ok = sh "ruby -c #{recipe} >/dev/null 2>&1"
        raise "Syntax error in #{recipe}" if not ok
      end
      if @server =~ /^local$/i
        sh chef_cmd
      else
        sh "rsync -rlP --rsh=\"ssh -p#@port\" --delete --exclude '.*' ./ #@server:#{REMOTE_CHEF_PATH}"
        sh "ssh -t -p #@port -A #@server \"cd #{REMOTE_CHEF_PATH}; #{chef_cmd} \""
      end
    end

    private
      def chef_cmd
        "sudo chef-solo -c config/solo.rb -j config/#@node.json"
      end

      def sh(command)
        system command
      end
  end
end
