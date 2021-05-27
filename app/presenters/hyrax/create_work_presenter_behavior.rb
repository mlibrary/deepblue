
module Hyrax

  module CreateWorkPresenterBehavior

    mattr_accessor :create_work_presenter_behavior_debug_verbose, default: false

    mattr_accessor :create_work_presenter_class
    self.create_work_presenter_class = ::Deepblue::SelectTypeListPresenter

    # A presenter for selecting a work type to create
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      if Flipflop.only_use_data_set_work_type?
        false
      else
        create_work_presenter.many?
      end
    end

    def draw_select_work_modal?
      create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
    end

  end

end
