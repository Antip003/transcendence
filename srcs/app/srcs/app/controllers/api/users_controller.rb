class Api::UsersController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :check_2fa!
  before_action :define_filters
  before_action :sign_out_if_banned
  before_action :find_user, only: %i[show update destroy accept_friend remove_friend]
  rescue_from ActiveRecord::RecordNotFound, :with => :user_not_found

  # GET /api/users.json
  def index
    @users = User.where(banned: false)
    render json: @users, only: @filters
  end

  # GET /api/users/id.json
  def show
    set_current_user
    render json: @user.as_json(
      only: @filters,
      include: { friends: { only: @filters }, requested_friends: {only: @filters} },
      :methods => :is_current
    )
  end

  # PATCH/PUT /api/users/id.json
  def update
    if current_user == @user
      if @user.update(user_params)
        render json: @user, only: @filters, status: :ok
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    else
      @user.errors.add :base, 'You have no permission'
      render json: @user.errors, status: :forbidden
    end
  end

  def add_friend
    @friended_user = User.find(params[:id])
    current_user.friend_request(@friended_user)
    render json: {}, status: :ok
  end

  def accept_friend
    @user.accept_request(User.find(params[:friend_id]))
    render json: {}, status: :ok
  end

  def remove_friend
    @user.remove_friend(User.find(params[:friend_id]))
    render json: {}, status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def find_user
    @user = if params[:id] == 'current' # /api/users/current.json
              current_user
            elsif is_numeric(params[:id])
              User.find(params[:id])
            else
              User.where(displayname: params[:id])
            end
  end
  # DRY filters for json responses
  def define_filters
    @filters = %i[id nickname displayname email admin banned online last_seen_at
                  wins loses elo avatar_url avatar_default_url]
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(%i[displayname avatar_url])
  end

  def is_numeric(str)
    r = Integer(str) rescue nil
    r == nil ? false : true
  end

  def user_not_found
    render json: {error: 'User not found'}, status: :not_found
  end

  def set_current_user
    User.current_user = current_user
  end
end
