require 'json'
require 'net/http'

BASE_URL = 'https://api.weather.gov'

def lambda_handler(event:, context:)
  begin
    latitude = event['queryStringParameters'].fetch('latitude', nil)
    longitude = event['queryStringParameters'].fetch('longitude', nil)

    if !latitude || !longitude
      return {
        statusCode: 400,
        body: JSON.generate({ error: 'Missing latitude or longitude query parameter' })
      }
    end

    points_data = get_points_data(latitude, longitude)
    
    if points_data[:error]
      return {
        statusCode: 400,
        body: JSON.generate({ error: points_data[:error] })
      }
    end
    
    forecast = get_forecast(points_data[:grid_id], points_data[:grid_x], points_data[:grid_y])

    {
      statusCode: 200,
      body: JSON.generate(forecast)
    }
  rescue StandardError => e
    {
      statusCode: 500,
      body: JSON.generate({ error: e.message })
    }
  end
end

def get_points_data(latitude, longitude)
  points_url = "#{BASE_URL}/points/#{latitude},#{longitude}"
  points_response = Net::HTTP.get(URI(points_url))
  points_data = JSON.parse(points_response)
  
  if points_data['status'] == 404 || points_data['status'] == 400
    return { error: points_data['detail'] }
  end
  
  properties = points_data['properties']
  
  if !properties || !properties['gridId'] || !properties['gridX'] || !properties['gridY']
    return { error: 'No forecast data for this location' }
  end
  
  {
    grid_id: properties['gridId'],
    grid_x: properties['gridX'],
    grid_y: properties['gridY']
  }
end

def get_forecast(grid_id, grid_x, grid_y)
  forecast_url = "#{BASE_URL}/gridpoints/#{grid_id}/#{grid_x},#{grid_y}/forecast"
  
  forecast_response = Net::HTTP.get(URI(forecast_url))
  forecast_data = JSON.parse(forecast_response)

  forecast_data['properties']['periods']
end


