# Newest-first keyset pagination on (date_time, id) for time series (readings, pictures).
# Unlike page numbers, a cursor stays stable while devices keep adding rows.
#
#   ?limit=100          page size (1..1000, default 100)
#   ?from=<ISO 8601>    date_time >= from
#   ?to=<ISO 8601>      date_time < to
#   ?cursor=<opaque>    next_cursor from the previous page
module KeysetPagination
  DEFAULT_LIMIT = 100
  MAX_LIMIT = 1000

  private

  # Returns [records, next_cursor]; next_cursor is nil on the last page.
  def paginate(scope)
    table = scope.klass.arel_table
    limit = page_limit
    scope = scope.where(table[:date_time].gteq(query_time(:from))) if params[:from].present?
    scope = scope.where(table[:date_time].lt(query_time(:to))) if params[:to].present?
    if params[:cursor].present?
      date_time, id = decode_cursor(params[:cursor])
      scope = scope.where("(#{scope.quoted_table_name}.date_time, #{scope.quoted_table_name}.id) < (?, ?)", date_time, id)
    end

    records = scope.reorder(date_time: :desc, id: :desc).limit(limit + 1).to_a
    next_cursor = encode_cursor(records[limit - 1]) if records.size > limit
    [records.first(limit), next_cursor]
  end

  def page_limit
    return DEFAULT_LIMIT if params[:limit].blank?

    limit = Integer(params[:limit], exception: false)
    raise Api::V1::BaseController::BadRequest, "limit must be an integer between 1 and #{MAX_LIMIT}" unless limit&.between?(1, MAX_LIMIT)

    limit
  end

  def query_time(name)
    Time.iso8601(params[name])
  rescue ArgumentError
    raise Api::V1::BaseController::BadRequest, "#{name} must be an ISO 8601 date time"
  end

  def encode_cursor(record)
    Base64.urlsafe_encode64("#{record.date_time.utc.iso8601(6)}|#{record.id}", padding: false)
  end

  def decode_cursor(cursor)
    date_time, id = Base64.urlsafe_decode64(cursor).split("|", 2)
    [Time.iso8601(date_time), Integer(id)]
  rescue ArgumentError, TypeError
    raise Api::V1::BaseController::BadRequest, "cursor is invalid"
  end
end
