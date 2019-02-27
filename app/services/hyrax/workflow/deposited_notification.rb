# frozen_string_literal: true

module Hyrax

  module Workflow

    class DepositedNotification < AbstractNotification

      private

        def curation_concern_notifications( user, message, subject )
          curation_concern = ActiveFedora::Base.find( work_id )
          current_user = user.user_key
          curation_concern.provenance_publish( current_user: current_user,
                                               event_note: 'DepositedNotification',
                                               message: message ) if curation_concern.respond_to? :provenance_publish
          curation_concern.email_rds_publish( current_user: current_user,
                                              event_note: 'DepositedNotification',
                                              message: message ) if curation_concern.respond_to? :email_rds_publish
        end

        def message
          "#{title} (#{link_to work_id, document_path}) was approved by #{user.user_key}. #{comment}"
        end

        def subject
          'Deposit has been approved'
        end

        def users_to_notify
          user_key = ActiveFedora::Base.find(work_id).depositor
          super << ::User.find_by(email: user_key)
        end

    end

  end

end
