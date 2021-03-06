class SendWeeklyCatchUpEmailWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, backtrace: true

  def perform
    zones = User.pluck('DISTINCT time_zone').select do |zone|
      Time.find_zone(zone) &&
      DateTime.now.in_time_zone(zone).hour == 6 &&
      DateTime.now.in_time_zone(zone).wday == 1
    end

    User.email_catch_up.where(time_zone: zones).find_each do |user|
      UserMailer.delay(queue: :low).catch_up(user.id, nil, 'weekly')
    end
  end
end
