class Api::TwoFactorController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :check_2fa, except: %i[validate]
  before_action :define_user

  def index
    if @user.otp_required_for_login?
      render json: {
        id: @user.id,
        otp_required_for_login: @user.otp_required_for_login,
        otp_qrcode: ''
      }
    else
      @user.update(otp_secret: User.generate_otp_secret)
      render json: {
        otp_required_for_login: @user.otp_required_for_login,
        otp_qrcode: @user.otp_qrcode.html_safe
      }
    end
  end

  def create
    return if @user.otp_required_for_login?
    if @user.validate_and_consume_otp!(params['otp'])
      @user.otp_required_for_login = true
      @user.otp_validated = true
      @user.save
      render json: {
        id: @user.id,
        otp_required_for_login: @user.otp_required_for_login,
        otp_qrcode: @user.otp_qrcode.html_safe
      }, status: :ok
    else
      @user.errors.add :otp, 'Bad OTP'
      render json: @user.errors, status: :forbidden
    end
  end

  def update
    return unless @user.otp_required_for_login?
    if @user.validate_and_consume_otp!(params['otp'])
      @user.otp_required_for_login = false
      @user.save
      render json: {
        id: @user.id,
        otp_required_for_login: @user.otp_required_for_login,
      }, status: :ok
    else
      @user.errors.add :otp, 'Bad OTP'
      render json: @user.errors, status: :forbidden
    end
  end

  def validate
    return if user_validated_2fa?
    if @user.validate_and_consume_otp!(params['otp'])
      @user.otp_validated = true
      @user.save
      flash[:info] = 'You are an admin.' if @user.admin
    else
      flash[:danger] = 'Bad OTP'
    end
    redirect_to root_path
  end

  private

  def define_user
    @user = current_user
  end
end
