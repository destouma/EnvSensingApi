# date_time is the moment a device took a measurement. Devices may omit it (the server time is used)
# or send an ISO 8601 timestamp; unparsable values and implausible clocks are rejected instead of
# being silently replaced.
module DeviceDateTime
  extend ActiveSupport::Concern

  EARLIEST = Time.utc(2000).freeze
  MAX_CLOCK_SKEW = 5.minutes

  included do
    before_validation :default_date_time
    validate :date_time_is_plausible
  end

  private

  def default_date_time
    self.date_time = Time.current if date_time_before_type_cast.blank?
  end

  def date_time_is_plausible
    if date_time.nil?
      errors.add(:date_time, "is not a valid ISO 8601 date time")
    elsif date_time < EARLIEST
      errors.add(:date_time, "must be after #{EARLIEST.year}, the device clock is probably not set")
    elsif date_time > MAX_CLOCK_SKEW.from_now
      errors.add(:date_time, "is in the future, the device clock is probably wrong")
    end
  end
end
