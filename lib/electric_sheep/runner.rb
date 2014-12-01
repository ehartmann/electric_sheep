require 'active_support/core_ext'

module ElectricSheep
  module Runner

    class SingleRun

      attr_reader :project

      def initialize(config, logger, project)
        @config=config
        @logger=logger
        @project=project
      end

      def run!
        project.benchmarked do
          @logger.info project.description ?
            "Executing \"#{project.description}\" (#{project.id})" :
            "Executing #{project.id}"
          project.each_item do |step|
            begin
              send("execute_#{executable_type(step)}", project, step)
            rescue Exception => e
              @logger.error e.message
              @logger.debug e
              return false
            end
          end
        end
        @logger.info "Project \"#{project.id}\" completed in %.3f seconds" %
          project.execution_time.round(3)
        true
      end

      def executable_type(executable)
        executable.class.name.underscore.split('/').last
      end

      def execute_shell(project, metadata)
        metadata.benchmarked do
            Shell::LocalShell.new(
              @config.hosts.localhost, project, @logger
            ).perform!(metadata)
        end
      end

      def execute_remote_shell(project, metadata)
        metadata.benchmarked do
          Shell::RemoteShell.new(
            project.last_product.host,
            project,
            @logger,
            metadata.user
          ).perform!(metadata)
        end
      end

      def execute_transport(project, metadata)
        transport = metadata.agent.new(project, @logger, metadata, @config.hosts)
        metadata.benchmarked do
          transport.perform!
        end
      end

    end

    class Inline

      def initialize(options)
        @config = options[:config]
        @logger = options[:logger]
        @project = options[:project]
      end

      def run!
        if @project.nil?
          run_all!
        else
          run_single!
        end
      end

      protected
      def run_all!
        failure = 0
        @config.each_item do |project|
          runner_state = run(project)
          failure += 1 if !runner_state
        end
        raise "One project fail" if failure == 1
        raise "#{failure} projects fail" if failure > 1
      end

      def run_single!
        project=@config.all.find{|p|p.id==@project}
        if project.nil?
          raise "Project \"#{@project}\" does not exist"
        else
          raise "Poject fail" unless run(project)
        end
      end

      def run(project)
        SingleRun.new(@config, @logger, project).run!
      end

    end
  end
end
