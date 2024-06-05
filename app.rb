require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"




get("/") do
erb:home
end

#####umbrella

get("/umbrella") do
  erb:umbrella_form
end

post("/process_umbrella") do
  @user_location = params.fetch("user_loc")
  encoder =  @user_location.gsub(" ", "+")

  gmaps_url="https://maps.googleapis.com/maps/api/geocode/json?address=#{encoder}&key=AIzaSyDKz4Y3bvrTsWpPRNn9ab55OkmcwZxLOHI"
  
  @result = HTTP.get(gmaps_url).to_s
  @parsed_result = JSON.parse(@result)
  @loc_hash = @parsed_result.dig("results", 0, "geometry", "location")
  @lat = @loc_hash.fetch("lat")
  @lng = @loc_hash.fetch("lng")

  pirate_weather = "https://api.pirateweather.net/forecast/3RrQrvLmiUayQ84JSxL8D2aXw99yRKlx1N4qFDUE/#{@lat},#{@lng}"

  @weather_result = HTTP.get(pirate_weather)
  response = JSON.parse(@weather_result)
  @currently = response.fetch("currently")
  @temperature = @currently.fetch("temperature")
  @summary = @currently.fetch("summary")


  precip_probability = @currently.fetch("precipProbability")

  if precip_probability > 0.10
    @result = "You might want to take an umbrella!"
  else
    @result = "You probably won't need an umbrella."  
  end
 
  erb:umbrella_response
end


#### single message

get("/message") do
  erb:ai_message_form
end

post("/process_single_message") do
  @chat_message = params.fetch("the_message")
  API_KEY = ENV.fetch("AI_KEY")

  request_headers_hash = {
  "Authorization" => "Bearer #{API_KEY}",
  "content-type" => "application/json"
}

request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant."
    },
    {
      "role" => "user",
      "content" => "#{@chat_message}"
    }
  ]
}

request_body_json = JSON.generate(request_body_hash)

raw_response = HTTP.headers(request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => request_body_json
).to_s

parsed_response = JSON.parse(raw_response)
content = parsed_response.fetch("choices")
text = content[0].fetch("message")
@text_response = text.fetch("content")

  erb:message_response
end


#### Chat GPT
get("/chat") do
  erb:ai_chat_form
  
end

post("/add_message_to_chat") do

  @chat_message = params.fetch("user_message")
  API_KEY = ENV.fetch("AI_KEY")

  request_headers_hash = {
  "Authorization" => "Bearer #{API_KEY}",
  "content-type" => "application/json"
}

request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant."
    },
    {
      "role" => "user",
      "content" => "#{@chat_message}"
    }
  ]
}

request_body_json = JSON.generate(request_body_hash)

raw_response = HTTP.headers(request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => request_body_json
).to_s

parsed_response = JSON.parse(raw_response)
content = parsed_response.fetch("choices")
text = content[0].fetch("message")
@text_response = text.fetch("content")
cookies.store(@chat_message, @text_response)

erb:chat_response


end

post("/clear_chat") do
  cookies.clear()
  redirect "/chat" 
end
