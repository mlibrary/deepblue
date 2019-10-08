# frozen_string_literal: true

module Hyrax

  module EmbargoesControllerBehavior
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
                                             "" ]
      # Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
      deactivate_embargo( curation_concern: curation_concern,
                          current_user: current_user,
                          copy_visibility_to_files: true )
      flash[:notice] = curation_concern.embargo_history.last
      if curation_concern.work? && curation_concern.file_sets.present? &&
            DeepBlueDocs::Application.config.embargo_allow_children_unembargo_choice
        redirect_to confirm_permission_path
      else
        redirect_to edit_embargo_path
      end
    end

    # Updates a batch of embargos
    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] }
      ActiveFedora::Base.find(batch).each do |curation_concern|
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

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.embargoes.index.manage_embargoes'), hyrax.embargoes_path
      add_breadcrumb t(:'hyrax.embargoes.edit.embargo_update'), '#'
    end

  end

end
