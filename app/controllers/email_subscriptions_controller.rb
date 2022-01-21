# frozen_string_literal: true

class EmailSubscriptionsController < ApplicationController

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_email_subscription, only: %i[ show edit update destroy ]

  # GET /email_subscriptions or /email_subscriptions.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    @email_subscriptions = EmailSubscription.all
  end

  # GET /email_subscriptions/1 or /email_subscriptions/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ]
    @email_subscription = EmailSubscription.find params[:id]
  end

  # GET /email_subscriptions/new
  def new
    raise CanCan::AccessDenied unless current_ability.admin?
    @email_subscription = EmailSubscription.new
  end

  # GET /email_subscriptions/1/edit
  def edit
    raise CanCan::AccessDenied unless current_ability.admin?
  end

  # POST /email_subscriptions or /email_subscriptions.json
  def create
    raise CanCan::AccessDenied unless current_ability.admin?
    @email_subscription = EmailSubscription.new(email_subscription_params)

    respond_to do |format|
      if @email_subscription.save
        format.html { redirect_to @email_subscription, notice: "Job status was successfully created." }
        format.json { render :show, status: :created, location: @email_subscription }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @email_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /email_subscriptions/1 or /email_subscriptions/1.json
  def update
    raise CanCan::AccessDenied unless current_ability.admin?
    respond_to do |format|
      if @email_subscription.update(email_subscription_params)
        format.html { redirect_to @email_subscription, notice: "Job status was successfully updated." }
        format.json { render :show, status: :ok, location: @email_subscription }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @email_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_subscriptions/1 or /email_subscriptions/1.json
  def destroy
    raise CanCan::AccessDenied unless current_ability.admin?
    @email_subscription.destroy
    respond_to do |format|
      format.html { redirect_to email_subscriptions_url, notice: "Job status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_subscription
      @email_subscription = EmailSubscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def email_subscription_params
      params.fetch(:email_subscription, {})
    end

end
