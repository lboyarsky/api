defmodule ApiWeb.ScheduleView do
  use ApiWeb.Web, :api_view
  alias ApiWeb.Plugs.Deadline
  alias JaSerializer.Relationship.HasOne

  def relationships(_, _) do
    %{
      stop: %HasOne{type: :stop, name: :stop, data: :stop, serializer: ApiWeb.StopView},
      trip: %HasOne{type: :trip, name: :trip, data: :trip, serializer: ApiWeb.TripView},
      route: %HasOne{type: :route, name: :route, data: :route, serializer: ApiWeb.RouteView},
      prediction: %HasOne{
        type: :prediction,
        name: :prediction,
        data: :prediction,
        serializer: ApiWeb.PredictionView,
        identifiers: :when_included,
        include: false
      }
    }
  end

  attributes([
    :arrival_time,
    :departure_time,
    :stop_sequence,
    :pickup_type,
    :drop_off_type,
    :timepoint,
    :direction_id
  ])

  def attributes(schedule, conn) do
    base = %{
      arrival_time: fn -> arrival_time(schedule, conn) end,
      departure_time: fn -> departure_time(schedule, conn) end,
      stop_sequence: schedule.stop_sequence,
      pickup_type: schedule.pickup_type,
      drop_off_type: schedule.drop_off_type,
      timepoint: schedule.timepoint?,
      direction_id: schedule.direction_id
    }

    opts = Map.get(conn.assigns, :opts, [])

    attributes =
      case Keyword.get(opts, :fields) do
        %{"schedule" => fields} ->
          Map.take(base, fields)

        _ ->
          base
      end

    Map.new(attributes, &apply_function_values/1)
  end

  def id(%{trip_id: trip_id, stop_id: stop_id, stop_sequence: stop_sequence}, _conn) do
    "schedule-" <> trip_id <> "-" <> stop_id <> "-" <> Integer.to_string(stop_sequence)
  end

  def preload(schedules, %{assigns: %{date: date}} = conn, include_opts)
      when is_list(schedules) do
    schedules = super(schedules, conn, include_opts)

    if include_opts != nil and Keyword.has_key?(include_opts, :prediction) do
      predictions = State.Prediction.prediction_for_many(schedules, date)

      for s <- schedules do
        p = Map.get(predictions, {s.trip_id, s.stop_sequence})
        Map.put(s, :prediction, p)
      end
    else
      schedules
    end
  end

  def preload(schedules, conn, include_opts), do: super(schedules, conn, include_opts)

  def prediction(%{prediction: prediction}, _conn), do: prediction

  def prediction(schedule, %{assigns: %{date: date}} = conn) do
    Deadline.check!(conn)
    State.Prediction.prediction_for(schedule, date)
  end

  def arrival_time(%{arrival_time: seconds_past_midnight}, conn) do
    format_time(seconds_past_midnight, conn)
  end

  def departure_time(%{departure_time: seconds_past_midnight}, conn) do
    format_time(seconds_past_midnight, conn)
  end

  defp format_time(nil, _) do
    nil
  end

  defp format_time(seconds, conn) do
    conn.assigns
    |> case do
      %{date_seconds: date_seconds} -> date_seconds
      %{date: date} -> date
    end
    |> DateHelpers.add_seconds_to_date(seconds)
    |> DateTime.to_iso8601()
  end

  defp apply_function_values({key, value}) when is_function(value, 0) do
    {key, value.()}
  end

  defp apply_function_values(key_value) do
    key_value
  end
end
