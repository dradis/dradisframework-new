# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :failure

  def create
    warden.authenticate!(*AuthenticationStrategies.strategies)
    redirect_to_target_or_default root_url
  end

  def destroy
    logout
    redirect_to login_path, notice: 'You have been logged out.'
  end

  def failure
    respond_to do |format|
      format.html do
        if request.xhr?
          head :not_found
        else
          flash[:alert] = warden_message if warden_message.present?
          session[:return_to] ||= return_to
          redirect_to login_path
        end
      end
      format.json { head :not_found }
      format.js { head :not_found }
    end
  end

  private

  def return_to
    if request.get?
      warden_options[:attempted_path]
    elsif request.post?
      request.env['HTTP_REFERER']
    end
  end
end
