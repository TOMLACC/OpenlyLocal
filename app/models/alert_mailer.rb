class AlertMailer < ActionMailer::Base
  @@auth_smtp_settings = YAML.load_file(File.join(Rails.root, 'config', 'smtp_gmail.yml'))['alerts'].symbolize_keys
  cattr_accessor :auth_smtp_settings

  def confirmation(subscriber)
    recipients subscriber.email
    from       'OpenlyLocal Alerts <alerts@openlylocal.com>'
    subject    "Activate your OpenlyLocal Planning Alerts subscription"
    sent_on    Time.now
    body       :subscriber => subscriber
  end

  def unsubscribe_confirmation(subscriber)
    recipients subscriber.email
    from       'OpenlyLocal Alerts <alerts@openlylocal.com>'
    subject    "You've been unsubscribed from OpenlyLocal Planning Alerts"
    sent_on    Time.now
    body       :subscriber => subscriber
  end
  
  def planning_alert(params={})
    unsubscribe_url = unsubscribe_alert_subscribers_url(:email => params[:subscriber].email, :token => params[:subscriber].unsubscribe_token)

    recipients params[:subscriber].email
    from       'OpenlyLocal Alerts <alerts@openlylocal.com>'
    subject    "New Planning Application: #{params[:planning_application].address}"
    sent_on    Time.now
    body       :planning_application => params[:planning_application], :subscriber => params[:subscriber], :unsubscribe_url => unsubscribe_url
    headers    'List-Unsubscribe' => "<#{unsubscribe_url}>"
  end
  
  private

  # This is a copy of the perform_delivery_smtp method from ActionMailer::Base,
  # the only difference being that +auth_smtp_settings+ has been substituted for
  # +smtp_settings+. Alternatives that modify smtp_settings to change this
  # method's behavior can provoke a race condition.
  # @see lib/action_mailer/base.rb
  def perform_delivery_smtp(mail)
    destinations = mail.destinations
    mail.ready_to_send
    sender = (mail['return-path'] && mail['return-path'].spec) || Array(mail.from).first

    smtp = Net::SMTP.new(auth_smtp_settings[:address], auth_smtp_settings[:port])
    smtp.enable_starttls_auto if auth_smtp_settings[:enable_starttls_auto] && smtp.respond_to?(:enable_starttls_auto)
    smtp.start(auth_smtp_settings[:domain], auth_smtp_settings[:user_name], auth_smtp_settings[:password],
               auth_smtp_settings[:authentication]) do |smtp|
      smtp.sendmail(mail.encoded, sender, destinations)
    end
  end
  
end
