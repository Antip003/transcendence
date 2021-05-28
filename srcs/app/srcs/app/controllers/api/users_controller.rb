class Api::UsersController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :check_2fa!
  before_action :define_filters
  before_action :sign_out_if_banned
  before_action :find_user, only: %i[show update destroy add_to_guild remove_from_guild]
  rescue_from ActiveRecord::RecordNotFound, :with => :user_not_found

  # GET /api/users.json
  def index
    @users = User.where(banned: false)
    render json: @users, only: @filters
  end

  # GET /api/users/id.json
  def show
    render json: @user.as_json(
      only: @filters,
      include: { friends: { only: @filters },
                 guild: { only: @guildfilters } }
    )
  end

  # PATCH/PUT /api/users/id.json
  def update
    if (current_user.admin? && @user != current_user && !@user.admin?) || current_user == @user
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

  def add_to_guild
    if (guild_master_action && @user != current_user)
      if !@user.guild_id
        @user.errors.add :base, 'No request found'
        render json: @user.errors, status: :forbidden
      end
      @user.update(guild_user_params)
      if (@user.guild_master == true)
          @user.guild_officer = false
          @user.save
          current_user.guild_master = false
          current_user.save
      end
    else
      if (@user == current_user) # && @user is invited
        # @user.id = .guild_id
           @user.guild_accepted = true
           @user.save
      else
        @user.errors.add :base, 'You have no permission'
        render json: @user.errors, status: :forbidden
      end
    end
  end

  def remove_from_guild
    if (!@user.guild_id)
      @user.errors.add :base, 'User is not any guild member'
      render json: @user.errors, status: :forbidden
    end
    if (current_user == @user || guild_master_action)
      #if @user.guild_master == true
        #  @guild = Guild.find(@user.guild_id)
        #   if @guild.members.size = 1 # ask to destroy guild end
        #@user.errors.add :base, 'Promote other user to master before leaving the guild.'
            #redirect to members list ?
        # render json: @user.errors, status: :forbidden
        # else
        @user.guild_accepted = false
        @user.guild_id = nil
        @user.guild_officer = false
        @user.guild_master = false #tmp for test
        @user.save
        render json: @user, only: @filters, status: :ok
        #  end
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
                  wins loses elo avatar_url avatar_default_url
                  guild_id guild_accepted guild_master guild_officer]
    @guildfilters = %i[name anagram]
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(%i[displayname avatar_url guild_id])
  end

  def guild_user_params
    params.permit(%i[guild_accepted guild_officer guild_master])
  end

  def guild_master_action
    current_user.guild_master = true && current_user.guild_id == @user.guild_id
  end

  def is_numeric(str)
    r = Integer(str) rescue nil
    r == nil ? false : true
  end

  def user_not_found
    render json: {error: 'User not found'}, status: :not_found
  end

end
