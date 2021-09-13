module Hyrax
  module Workflow
    class DraftCreationNotification < AbstractNotification
      private

        def subject
          'Draft work created'
        end

        def message
          "#{title} (#{link_to work_id, document_path}) was created by #{user.user_key} as a draft work"
        end

        def users_to_notify
          super << user
        end
    end
  end
end
