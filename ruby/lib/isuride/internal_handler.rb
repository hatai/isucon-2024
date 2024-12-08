# frozen_string_literal: true

require 'isuride/base_handler'

module Isuride
  class InternalHandler < BaseHandler
    # このAPIをインスタンス内から一定間隔で叩かせることで、椅子とライドをマッチングさせる
    # GET /api/internal/matching
    get '/matching' do
      ride = db.query('SELECT id FROM rides WHERE chair_id IS NULL ORDER BY created_at LIMIT 1').first
      unless ride
        halt 204
      end

      ride_id = ride.fetch(:id)

      # ライド中ではない、最も近くて早い椅子を探す
      matched = db.xquery("SELECT chairs.id, chairs.name, chair_models.speed,
       chair_locations.latitude, chair_locations.longitude,
       ABS(chair_locations.latitude - rides.pickup_latitude) + ABS(chair_locations.longitude - rides.pickup_longitude) AS distance
      FROM chairs
      JOIN chair_locations ON chairs.id = chair_locations.chair_id
      JOIN chair_models ON chairs.model = chair_models.name
      LEFT JOIN (
        SELECT DISTINCT rides.chair_id
        FROM rides
        JOIN ride_statuses ON rides.id = ride_statuses.ride_id
        WHERE ride_statuses.status IN ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING')
      ) AS active_chairs ON chairs.id = active_chairs.chair_id
      JOIN rides ON rides.id = ?
      WHERE chairs.is_active = TRUE
      AND active_chairs.chair_id IS NULL
      ORDER BY distance ASC, chair_models.speed DESC
      LIMIT 1", ride_id).first

      unless matched
        halt 204
      end

      db.xquery('UPDATE rides SET chair_id = ? WHERE id = ?', matched['id'], ride_id)
      204
    end
  end
end
