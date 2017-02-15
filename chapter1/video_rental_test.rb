require "minitest"
require "minitest/autorun"
require "minitest/spec"
require "minitest/pride"
require_relative "video_rental"

describe Customer do
  subject { Customer.new("Smith") }
  let(:rent) do
    lambda { |movie, days| subject.add_rental(Rental.new(movie, days)) }
  end
  let(:regular_movie)   { Movie.new("Regent", Movie::REGULAR) }
  let(:new_movie)       { Movie.new("Newton", Movie::NEW_RELEASE) }
  let(:childrens_movie) { Movie.new("Chills", Movie::CHILDRENS) }


  it "has a name" do
    subject.name.must_equal "Smith"
  end

  it "keeps a record of rentals" do
    rent[:movie1, 2]
    rent[:movie2, 7]

    subject.rentals.length.must_equal 2
    subject.rentals[0].movie.must_equal :movie1
    subject.rentals[1].movie.must_equal :movie2
  end

  describe "#html_statement" do
    before do
      #                          fee     points
      # =======================================
      rent[regular_movie,   1]  # 2       1 pts
      rent[regular_movie,   7]  # 9.5     1 pts
      rent[childrens_movie, 5]  # 4.5     1 pts
      rent[new_movie,       6]  # 18      2 pts
      # =======================================
      #              total:       34.0    5 pts
    end

    it "returns html output" do
      subject.html_statement.must_match /<h1>.*<\/h1>/
    end

    it "prints the correct values formatted as HTML" do
      subject.html_statement.must_equal <<~HTML
        <h1>Rentals for <em>Smith</em></h1>
        <p><ul>
        <li>Regent: 2</li>
        <li>Regent: 9.5</li>
        <li>Chills: 4.5</li>
        <li>Newton: 18</li>
        </ul></p>
        <p>You owe <em>34.0</em></p>
        <p>Congratulations, you earned <em>5 frequent renter points!</em></p>
      HTML
      .chomp
    end
  end

  describe "#statement" do
    it "outputs a String" do
      subject.statement.must_be_instance_of String
    end

    it "includes a header line with the customer’s name" do
      subject.statement.must_include "Rental Record for Smith"
    end

    describe "rental costs for 1 day" do
      before do
        rent[regular_movie, 1]
        rent[new_movie,     1]
        rent[childrens_movie, 1]
      end

      it "includes movie title and fee for each rented movie" do
        s = subject.statement
        s.must_match /^\tRegent\t2$/
        s.must_match /^\tNewton\t3$/
        s.must_match /^\tChills\t1\.5$/
      end

      it "includes the total fee for all rentals" do
        subject.statement.must_include "Amount owed is 6.5"
      end

      it "includes frequent renter points earned" do
        subject.statement.must_include "You earned 3 frequent renter points"
      end
    end

    describe "frequent renter points" do
      it "bonus point for each new release movie rented for 2 or more days" do
        rent[new_movie, 1]
        rent[new_movie, 2] # <-- bonus point
        rent[regular_movie, 3]
        subject.statement.must_include "You earned 4 frequent renter points"
      end
    end

    describe "regular movie, more than two days" do
      it "costs 2 dollars plus 1.5 dollars for each additional day" do
        rent[regular_movie, 4]
        subject.statement.must_match /^\tRegent\t#{2 + 1.5 * 2}$/
      end
    end

    describe "childrens movie, more than three days" do
      it "costs 1.5 dollars plus 1.5 dollars for each additional day" do
        rent[childrens_movie, 6]
        subject.statement.must_match /^\tChills\t#{1.5 + 1.5 * 3}$/
      end
    end

    describe "complete example with different numbers" do
      it "prints the statement as expected" do
        #                          fee     points
        # =======================================
        rent[regular_movie, 2]   # 2       1
        rent[regular_movie, 3]   # 3.5     1
        rent[new_movie, 1]       # 3       1
        rent[new_movie, 3]       # 9       2
        rent[childrens_movie, 3] # 1.5     1
        rent[childrens_movie, 4] # 3       1
        # =======================================
        #              total:      22.0    7

        subject.statement.must_equal <<~STATEMENT
          Rental Record for Smith
          \tRegent\t2
          \tRegent\t3.5
          \tNewton\t3
          \tNewton\t9
          \tChills\t1.5
          \tChills\t3.0
          Amount owed is 22.0
          You earned 7 frequent renter points
        STATEMENT
        .chomp
      end
    end
  end
end

describe Rental do
  subject { Rental.new(:movie, 5) }

  it "remembers a movie" do
    subject.movie.must_equal :movie
  end

  it "remembers the number of days" do
    subject.days_rented.must_equal 5
  end
end

describe Movie do
  let(:regular) { Movie::REGULAR }
  let(:new_release) { Movie::NEW_RELEASE }

  it "has constants for price codes" do
    Movie::REGULAR.must_equal 0
    Movie::NEW_RELEASE.must_equal 1
    Movie::CHILDRENS.must_equal 2
  end

  it "has a title" do
    movie = Movie.new "Alien", regular
    movie.title.must_equal "Alien"
  end

  it "has a price code" do
    movie = Movie.new "Alien", regular
    movie.price_code.must_equal regular
  end

  it "allows changing the price code" do
    movie = Movie.new "Alien", new_release
    movie.price_code = regular
    movie.price_code.must_equal regular
  end

  it "does not allow changing the title" do
    movie = Movie.new "Alien", regular
    proc {movie.title = "x"}.must_raise NoMethodError
  end
end
