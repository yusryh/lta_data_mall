require "lta_data_mall/version"
require 'net/http'
require 'json'
require 'date'

# An unofficial API Wrapper for LTA Data Mall
#
# Author::    Yusry Harfuddin
# Copyright:: Copyright (c) 2016-2017 Yusry Harfuddin
# License::   AGPL-3.0

module LtaDataMall
  class Configuration
    attr_accessor :account_key
  end

  # Get configuration block
  def self.configuration
    if @configuration.nil?
      @configuration = Configuration.new
    end
    if block_given?
      yield @configuration
    else
      @configuration
    end
  end

  class HttpClient #:nodoc:
    def self.call(url, headers)
    end

    def self.json(endpoint, parameters)
      uri = URI.parse(endpoint)
      uri.query = URI.encode_www_form(parameters)

      http = Net::HTTP.new(uri.host, uri.port)

      get_request = Net::HTTP::Get.new(uri.to_s)
      get_request['AccountKey'] = ::LtaDataMall.configuration.account_key

      http.start do |http|
	      response = http.request(get_request)

        return OpenStruct.new ({
          date: response['Date'],
          body: response.body
        })
      end
    end
  end

  class BusArrival
    class Stop
      attr_reader :response_datetime, :stop_code, :services

      def initialize(service_data_string, response_datetime) #:nodoc:
        @response_datetime = DateTime.parse(response_datetime)
        service_data = JSON.parse(service_data_string)
        @stop_code = service_data['BusStopCode']

        @services = []
        service_data['Services'].each do |service|
          @services << Service.new(service)
        end
      end
    end

    class Service
      attr_reader :no, :operator, :arrivals

      OPERATOR_TYPES = {
        'SBST' => :sbst,
        'SMRT' => :smrt,
        'TTS'  => :tts,
        'GAS'  => :gas
      }

      def initialize(service_data) #:nodoc:
        @no = service_data['ServiceNo']
        @operator = OPERATOR_TYPES[service_data['Operator']]

        @arrivals = []
        ['NextBus', 'NextBus2', 'NextBus3'].each do |next_bus_key|
          @arrivals << Bus.new(service_data[next_bus_key])
        end
      end
    end

    class Bus

      attr_reader :origin_code, :destination_code, :estimated_arrival,
        :latitude, :longitude, :visit_number, :load, :is_wab, :vehicle

      alias_method :is_wab?, :is_wab

        LOAD_TYPES = {
          'SEA' => :seats_available,
          'SDA' => :standing_available,
          'LSD' => :limited_standing
        }

        VEHICLE_TYPES = {
          'SD' => :single_deck,
          'DD' => :double_deck,
          'BD' => :articulated
        }

      def initialize(service_data) #:nodoc:
        @origin_code = service_data['OriginCode']
        @destination_code = service_data['DestinationCode']
        begin
          @estimated_arrival = DateTime.parse(service_data['EstimatedArrival'])
        rescue
          @estimated_arrival = nil
        end
        @latitude = service_data['Latitude']
        @longitude = service_data['Longitude']
        @visit_number = service_data['VisitNumber'].to_i
        @load = LOAD_TYPES[service_data['Load']]
        @is_wab = service_data['Feature'] == 'WAB'
        @vehicle = VEHICLE_TYPES[service_data['Type']]
      end

      # Returns true if there are seats available
      def has_seats?
        @load == :seats_available
      end
    end

    ENDPOINT_URL = 'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2'

    def get_bus_arrival(bus_stop_code, bus_route = nil)
      parameters = { 'BusStopCode' => bus_stop_code.to_s }
      parameters['ServiceNo'] = bus_route unless (bus_route.nil?|| bus_route == '') 
      response = ::LtaDataMall::HttpClient.json(ENDPOINT_URL, parameters)

      Stop.new(response.body, response.date)
    end
  end
end
