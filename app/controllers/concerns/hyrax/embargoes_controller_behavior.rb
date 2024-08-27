# frozen_string_literal: true
# Reviewed: hyrax4
module Hyrax

  module EmbargoesControllerBehavior

    mattr_accessor :embargo_controller_behavior_debug_verbose,
                          default: Rails.configuration.hyrax_embargo_controller_behavior_debug_verbose

    extend ActiveSupport::Concern
    include Hyrax::ManagesEmbargoes
    include Hyrax::Collections::AcceptsBatches
    include ::Hyrax::EmbargoHelper

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.embargoes.index.manage_embargoes'), hyrax.embargoes_path
      authorize! :index, Hydra::AccessControls::Embargo
    end

    # Removes a single embargo
    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                             "" ] if embargo_controller_behavior_debug_verbose
      # Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
      deactivate_embargo( curation_concern: curation_concern,
                          current_user: current_user,
                          copy_visibility_to_files: true )
      flash[:notice] = curation_concern.embargo_history.last
      if curation_concern.work? && curation_concern.file_sets.present? &&
                    Rails.configuration.embargo_allow_children_unembargo_choice
        redirect_to confirm_permission_path
      else
        redirect_to edit_embargo_path
      end
    end

    # Updates a batch of embargos
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def update
      filter_docs_with_edit_access!
      copy_visibility = []
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] } if params[:embargoes]
      af_objects = ::PersistHelper.find_many(batch)
      af_objects.each do |curation_concern|
        # Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
        copy_visibility_to_files = if curation_concern.file_set?
                                     true
                                   else
                                     copy_visibility.include?(curation_concern.id)
                                   end
        deactivate_embargo( curation_concern: curation_concern,
                            current_user: current_user,
                            copy_visibility_to_files: copy_visibility_to_files )
      end
      redirect_to embargoes_path, notice: t('.embargo_deactivated')
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end

    def edit
      @curation_concern = Hyrax::Forms::WorkEmbargoForm.new(curation_concern).prepopulate! if
        Hyrax.config.use_valkyrie?
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.embargoes.index.manage_embargoes'), hyrax.embargoes_path
      add_breadcrumb t(:'hyrax.embargoes.edit.embargo_update'), '#'
    end

    private

    def embargo_history(concern)
      concern.try(:embargo_history) ||
        concern.try(:embargo)&.embargo_history
    end
  end
end
