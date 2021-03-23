require 'logger'
require 'resque'

# monkey override class file

module IrusAnalytics
  module Controller
    module AnalyticsBehaviour 
      def send_analytics
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ]
        # logger = Logger.new(STDOUT) if logger.nil?
        logger = Rails.logger
        # Retrieve required params from the request
        if request.nil?
           logger.warn("IrusAnalytics::Controller::AnalyticsBehaviour.send_analytics exited: Request object is nil.")
        else
          # Should we filter this request...
          unless filter_request?(request)
            # Get Request data
            client_ip = request.remote_ip if request.respond_to?(:remote_ip)
            user_agent = request.user_agent if request.respond_to?(:user_agent)
            file_url = request.url if request.respond_to?(:url)
            referer = request.referer if request.respond_to?(:referer)
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "client_ip=#{client_ip}",
                                                   "user_agent=#{user_agent}",
                                                   "file_url=#{file_url}",
                                                   "referer=#{referer}",
                                                   "" ]

             # Defined locally
            datetime = datetime_stamp
            source_repository = source_repository_name

            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "self.class.name=#{self.class.name}",
                                                   "datetime=#{datetime}",
                                                   "source_repository=#{source_repository}",
                                                   "self.respond_to?(:item_identifier)=#{self.respond_to?(:item_identifier)}",
                                                   "" ]

            # These following should defined in the controller class including this module
            identifier = self.item_identifier if self.respond_to?(:item_identifier)

            analytics_params = { date_stamp: datetime,
                                 client_ip_address: client_ip,
                                 user_agent: user_agent,
                                 item_oai_identifier: identifier,
                                 file_url: file_url,
                                 http_referer: referer,
                                 source_repository: source_repository }
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "self.class.name=#{self.class.name}",
                                                   "analytics_params=#{analytics_params}",
                                                   "" ]

            if irus_server_address.nil? 
              # In development and test Rails environment without irus_server_address we log in debug  
              if rails_environment == "development" || rails_environment == "test"
                logger.debug("IrusAnalytics::ControllerBehaviour.send_irus_analytics params extracted #{analytics_params}")
              else
                logger.error("IrusAnalytics::Controller::AnalyticsBehaviour.send_analytics exited: Irus Server address is not set.")
              end

            else
              begin
                Resque.enqueue(IrusClient, irus_server_address, analytics_params)
              rescue Exception => e
                logger.error("IrusAnalytics::Controller::AnalyticsBehaviour.send_analytics error: Problem enquing the analytics with Resque. Error: #{e}")
              end
            end
          end
        end
      end

      private


      # Returns UTC iso8601 version of Datetime
      def datetime_stamp
        Time.now.utc.iso8601
      end

      def source_repository_name
        IrusAnalytics.configuration.source_repository
      end

      def irus_server_address
        IrusAnalytics.configuration.irus_server_address
      end

      def filter_request?(request)
        filter_request = false 
        # If we can't determine the request.user_agent we should filter it...
        if request.respond_to?(:user_agent)
          filter_request = !request.headers['HTTP_RANGE'].nil?  || robot_user_agent?(request.user_agent) 
        else
          filter_request = true
        end
        filter_request
      end

      def robot_user_agent?(user_agent)
        IrusAnalytics::UserAgentFilter.instance.filter_user_agent?(user_agent)
      end

      def rails_environment
        unless Rails.nil?
          return Rails.env.to_s 
        end
      end

    end
  end
end
