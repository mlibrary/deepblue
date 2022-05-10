# frozen_string_literal: true

# monkey override

module Hyrax

  module Workflow

    class DepositedNotification < AbstractNotification

      private

        def curation_concern_notifications( user, message, subject )
          curation_concern = ::PersistHelper.find( work_id )
          current_user = user.user_key
          curation_concern.workflow_publish( current_user: current_user,
                                             event_note: 'DepositedNotification',
                                             message: message ) if curation_concern.respond_to? :workflow_publish
        end

        def message
          I18n.t('hyrax.notifications.workflow.deposited.message', title: title, link: (link_to work_id, document_path),
                 user: user.user_key, comment: comment)
        end

        def subject
          I18n.t('hyrax.notifications.workflow.deposited.subject')
        end

        def users_to_notify
          user_key = ::PersistHelper.find(work_id).depositor
          super << ::User.find_by(email: user_key)
        end

    end

  end

end
