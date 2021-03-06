class BotBooking
  PURCHASED_ATTEMPTS = 3.freeze
  class ReservationFailure < StandardError; end

  def initialize(reservation)
    @reservation = reservation
    @trainline_url = "https://www.trainline.fr"
    @browser = Capybara.current_session
    @driver = @browser.driver.browser
    @countdown = 0
  end

  def flow
    begin
      @reservation.process
      sign_in
      search_for_results
      pick_the_best_result
      choose_a_seat
      checkout
      @driver.quit
    rescue NoMethodError, Capybara::ElementNotFound
      @reservation.failure
      raise ReservationFailure
    end
  end

  def sign_in
    puts "Hello 💩"
    sleep 1
    visit_trainline
    sleep 1
    @browser.find('.header__signin-button').click
    sleep 1
    @browser.find('#signin-form input[type=email]').set(@reservation.user.login_trainline)
    sleep 1
    @browser.find('#signin-form input[type=password]').set(@reservation.user.password_trainline)
    sleep 1
    @browser.find('.signin__button').click
    sleep 1
  end

  def search_for_results
    sleep 1
    puts "Looking for a ticket for #{@reservation.user.email}"
    @browser.visit("#{@trainline_url}/search/"\
      "#{@reservation.city_departure}/"\
      "#{@reservation.city_arrival}/"\
      "#{@reservation.date_departure.to_s}-"\
      "#{@reservation.time_departure.strftime('%H:%M')}")
    sleep 1
    submit_search
  end

  def pick_the_best_result
    sleep 2
    puts "PICKING BEST RESULT for #{@reservation.date_departure}"
    @browser.all('.search__results--table .search__results--line .first span.time').each_with_index do |node, index|
      @browser.execute_script("$($('.search__results--line')[#{index}]).css('background','pink')")
      puts "NODE #{index} for #{node.text}"
      if node.text[0..4].to_i >= @reservation.time_departure.hour
        puts "NODE MATCH #{index} for #{node.text}"
        if @browser.all('.search__results--table .search__results--line .third')[index]['class'].include? 'unsellable'
          puts "NODE UNAVAILABLE #{index} for #{node.text} count #{@countdown}"
          if @countdown >= PURCHASED_ATTEMPTS || @countdown < 0
            @countdown = -1
            next
          end
          @countdown += 1 if @countdown >= 0
          # sleep 60
          sleep 1
          @driver.navigate.refresh
          sleep 2
          submit_search
          sleep 1
          pick_the_best_result
          break
        end
        puts "NODE CLICKED #{index} for #{node.text}"
        node.click
        break
      end
    end
  end

  def choose_a_seat
    seat_index = Reservation::SEAT_PREFERENCES.find_index(@reservation.seat_preference)
    sleep 5
    puts "PICK SEAT #{@reservation.seat_preference}"
    @browser.all('.selected-folder__seat--seats option').each_with_index do |node, index|
      if index == seat_index
        node.click
        break
      end
    end
    sleep 1
  end

  def checkout
    sleep 4
    @browser.find('.selected-folder__button button').click
    puts "ADD TO CART"
    sleep 6
    puts "PAY TICKET -> $0"
    @browser.find('.cart__group--last button').click
    sleep 2
    puts "I AGREE WITH SNCF"
    @browser.find('.modal-dialog form span').click
    sleep 2
    @browser.click_button('Valider')
    sleep 2
    @reservation.success
    puts "TICKET BOOKED"
  end

  def visit_trainline
    puts "VISIT TRAINLINE"
    @browser.visit(@trainline_url)
  end

  def submit_search
    @browser.find('.search__button').click
  end
end
