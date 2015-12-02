class SubscriptionsController < ApplicationController
  def subscribe_sms
    @phone = params["subscriber_phone"]
    if @phone.blank?
      flash[:danger] = 'You must supply a valid phone number'
      redirect_to :action => 'subscribe'
      return
    end

    begin 
      sns = Aws::SNS::Client.new(region: 'us-east-1')
      resp = sns.subscribe({
        topic_arn: "arn:aws:sns:us-east-1:068709296373:rx_interaction_notification", # required
        protocol: "sms", # required
        endpoint: @phone,
      })
      flash[:success] = "A subscription request was successfully sent to #{@phone}."
      redirect_to :action => 'home', :controller => 'application'
    rescue
      flash[:danger] = 'Error occurred while processing subscription'
      redirect_to :action => 'subscribe'
      return
    end
  end

  def subscribe_email
    @email = params["subscriber_email"]
    if @email.blank?
      flash[:danger] = 'You must supply a valid email address'
      redirect_to :action => 'subscribe'
      return
    end

    begin 
      sns = Aws::SNS::Client.new(region: 'us-east-1')
      resp = sns.subscribe({
        topic_arn: "arn:aws:sns:us-east-1:068709296373:rx_interaction_notification", # required
        protocol: "email", # required
        endpoint: @email,
      })

      flash[:success] = "A subscription request was successfully sent to #{@email}."
      redirect_to :action => 'home', :controller => 'application'
    rescue
      flash[:danger] = 'Error occurred while processing subscription'
      redirect_to :action => 'subscribe'
      return
    end
  end

  def subscribe
  end
end
