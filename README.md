# `lta_data_mall` An unofficial client for LTA Data Mall API

`lta_data_mall` is an unofficial client for accessing LTA Data Mall APIs.

Currently, only the Bus Arrival API (Version 2) can be accessed via this gem.
Other APIs will be progressively added.

## Links

* Homepage: <https://www.yusry.name/gems/lta_data_mall>
* Git Repository: <https://www.github.com/yusryh/lta_data_mall>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lta_data_mall' git: 'https://www.github.com/yusryh/lta_data_mall'
```

This gem does not rely on any additional gems or libraries other than `StdLib`.

And then execute:

    $ bundle

<!-- Or install it yourself as:

    $ gem install lta_data_mall
-->
## Usage

Prior to usage, please ensure that you have obtained a API Account Key. You can
obtain one from
<https://www.mytransport.sg/content/mytransport/home/dataMall.html>.

First, create an initialiser. If you are using Rails, you can create
`/config/initializers/lta_data_mall.rb` and add your account key.

```ruby
LtaDataMall.configuration do |config|
  config.account_key = 'My Account Key'
end
```

To get bus arrival information, instantiate a copy of the `LtaDataMall::BusArrival`
class and call the `.get_bus_arrival` method and supply the bus stop code as a
`String` and an optional bus route as a `String`

```ruby
bus_arrival = LtaDataMall::BusArrival.new
stop_83139 = bus_arrival.get_bus_arrival('83139')
```
<!-- stop_83139_bus_15 = bus_arrival.get_bus_arrival('83139', '15') -->

This will return an instance of the `LtaDataMall::BusArrival::Stop` class. You
have the following instance methods in this class.

* `.response_datetime` - Returns a `DataTime` object containinng the API server's
response timestamp. You can use this to calculate time offsets.
* `.stop_code` - The bus stop code of this API call request.
* `.services` - An array of `LtaDataMall::BusArrival::Service` objects containing
bus services and their arrival information.

`LtaDataMall::BusArrival::Service` has the following instance methods.

* `.no` - Route number
* `.operator` - A symbol designating one of the following bus operators.
  * `:sbst` - SBS Transit
  * `:smrt` - SMRT Buses
  * `:tts` - Tower Transit Singapore
  * `:gas` - Go-Ahead Singapore
* `.arrivals` - An array of `LtaDataMall::BusArrival::Bus` objects containing
the specific arrival information.

`LtaDataMall::BusArrival::Bus` has the following instance methods.

* `.origin_code` - The bus stop code where this bus started its trip from.
* `.destination_code` - The bus stop code where this bus will end its trip at.
* `.estimated_arrival` - A `DateTime` instance indicating the bus' approximate
time of arrival.
* `.visit_number` - The bus' visit count to this particular bus stop on this
particular trip.
* `.load` - A symbol indicating the bus' load.
  * `:seats_available` - Seats are available
  * `:standing_available` - Standing space is available
  * `:limited_standing` - There is limited standing space
* `.is_wab?` - Indicates if the bus is a Wheel-Chair Accessible bus.
* `.vehicle` - A symbol indicating the vehicle type.
  * `:single_deck` - A single-deck rigid bus. For example, a Scania K230UB or a Mercedes Benz Citaro, MAN A22, Volvo B10BLE (non-WAB), or Volvo B10M (non-WAB)
  * `:double_deck` - A double-deck rigid bus. For axample, a Volvo B9TL, Dennis Enviro 500, MAN A95, Volvo (Super) Olympian (non-WAB), or Dennis Trident III (non-WAB).
  * `:articulated` - A articulated (or bendy) single-deck bus. For example, a Mercedes Benz O405 (non-WAB), or MAN A24.

## Understanding Green/Red/White Plates and Visit Numbers

In case LTA's documentation is not clear enough, I am giving a few examples to
allow you to understand this matter.

**Disclaimer**: I am a a bus, train, plane, and mobile crane enthusiast. I am
explaining this in my personal capacity as an enthusiast.

Bus operators in Singapore generally use coloured plates to indicate bus routes
that visit the same bus stop more than once but heading towards different directions.
These coloured plates are sometimes also use to indicate dual-circuit bus routes.
For example, clock-wise and anti-clockwise routes. Additionally, there are bus
routes that have north-south or east-west loops that visit an interchange between
loop, that do not use any sort of coloured plates, but visually using a terminating
indicator in its route number.

### Green-White plates
Green-White plates are generally used to indicate bus routes that operate in a
clockwise and anti-clockwise direction. These buses are usually given separate
bus route numbers, for example, 225G/225W, 243G/243W, and 410G/410W. So these
generally do not need special handling.

### Red-White plates
Red-White plates are usually used to indicate indicate bus routes that visit the
same physically bus stop while operating in different directions. For example,
route 155 visits the same multiple bus stops in MacPherson estate while heading
towards both Bedok and Toa Payoh interchanges. For route 155, use `.origin_code`
and `.destination_code` to determine the plate colour. Other known services
operating in such a manner are routes:

* 21
* 123
* 124
* 125
* 129
* 131
* 136
* 139
* 186

Generally, 'red' indicates direction 1 and 'white' indicates direction 2. LTA's
API would return two `LtaDataMall::BusArrival::Service` entries; one for each direction.

In other cases, you need to utilise `.visit_number` to determine its plate
colour. These routes are generally loop services that visit the same bus stop
before and after its looping point. For example, route 60 visits bus stops
84501 and 84511 both before (`.visit_number` of 1) and after (`.visit_number` of
2) its looping point. Other known services operating in this manner are routes:

* 73
* 315
* 317

Generally, 'red' indicates heading towards looping point, and 'white' indicates
heading from looping point and back to its origin.

### East-West, North-South loops
Buses operating in this manner are usually due to route amalgamation of 2 or more
formerly-looping bus services that operated from the same origin bus stop.
They generally operate in the following manner:

* Origin bus stop
* Operate first loop
* Visit the origin bus stop again.
* Operate second loop (if not terminating/ending)
* Back at origin bus stop and repeat.

These buses usually operate continuously. The rationale is to allow travelers to
conveniently travel between both loops.

Buses that will not be proceeding to operate the next loop will indicate an E or
T (for Ending or Terminating) in their route numbers prior to beginning their
current loop. This is not indicated in the API and thus there is no way to find
out whether an arriving bus is terminating at the end of the loop or proceeding
to the next loop.

Known bus routes that operate in this manner are the following routes:

* 358
* 359
* 911
* 912
* 913

There is another bus route - 307 - that operates in a similar manner, except that
it does not return to the Origin bus stop when traveling from the first loop
to the second loop; it does that only when traveling from the second to first
loop.

#### Identifying The Loop

For routes 358, and 359, use `.visit_number` to determine the loop.

For routes 911, 912, and 913, Woodlands Interchange is indicated with a different
bus stop code - 46008 instead of 46009 - when commencing its second loop. Thus,
bus stop code 46009 would only indicate buses heading towards the first loop,
while 46008 indicates bus heading towards the second loop.

### Airport Bus Route 36

Since the handover of route 36 to Go-Ahead Singapore, route 36 has been operated
in a fairly confusing manner.

Officially, route 36 begins and ends its trip at Changi Airport Passenger
Terminal Building 2 (bus stop code 95129).

Prior to hand-over, the buses operated in a continuous loop, which meant that
boarding the bus prior to bus stop 95129, meant that you could continue the trip
beyond that bus stop.

Since the hand-over, buses usually do terminate at bus stop 95129 (Terminal 2).
However, the buses will actually begin their trip at Terminal 3, proceed to
Terminal 1 and then Terminal 2 before officially commencing the trip. As
trip commencement officially starts at Terminal 2, there is no indication via
the use of `.visit_number` at Terminals 3, 1, or 2, that indicates whether the
bus is beginning or terminating.

Generally speaking, if a particular bus is crowded at Terminal 3 (the first
terminal building it visits), it is likely to be a terminating trip. Likewise,
if it's empty at Terminal 3, it is likely to be starting a new trip.

<!-- ## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://www.github.com/yusryh/lta_data_mall.
