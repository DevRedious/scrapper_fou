# Le Scrappeur Fou

A Ruby web scraping project for THP. This project contains three scrapers:
- **Dark Trader**: Fetches cryptocurrency prices from CoinMarketCap
- **Mairie Christmas**: Fetches email addresses of town halls in Val d'Oise (France)
- **Cher Député** (BONUS): Fetches information about French deputies

## Installation

```bash
git clone <repo-url>
cd le-scrappeur-fou

bundle install
```

## Usage

### Dark Trader - Cryptocurrencies

```bash
ruby lib/dark_trader.rb
```

This script fetches all cryptocurrency prices from CoinMarketCap and stores them in an array of hashes:

```ruby
[
  { "BTC" => 45000.00 },
  { "ETH" => 3200.50 },
]
```

### Mairie Christmas - Town Hall Emails

```bash
ruby lib/mairie_scraper.rb
```

This script fetches town hall emails from Val d'Oise department using the official service-public.gouv.fr directory:

```ruby
[
  { "Argenteuil" => "mairie@argenteuil.fr" },
  { "Cergy" => "contact@cergy.fr" },
]
```

### Cher Député (BONUS) - French Deputies

```bash
ruby lib/depute_scraper.rb
```

This script fetches information about French deputies from the National Assembly website:

```ruby
[
  {
    "first_name" => "Gabriel",
    "last_name" => "Attal",
    "email" => "gabriel.attal@assemblee-nationale.fr"
  },
]
```

## Using as a Module

```ruby
require_relative 'lib/dark_trader'
require_relative 'lib/mairie_scraper'
require_relative 'lib/depute_scraper'

trader = DarkTrader.new
cryptos = trader.fetch_all_cryptos

scraper = MairieScraper.new
emails = scraper.fetch_all_emails

depute_scraper = DeputeScraper.new
deputes = depute_scraper.fetch_all_deputes
```

## Tests

```bash
bundle exec rspec

bundle exec rspec spec/dark_trader_spec.rb
bundle exec rspec spec/mairie_scraper_spec.rb
bundle exec rspec spec/depute_scraper_spec.rb

bundle exec rspec --tag slow
```

## Project Structure

```
le-scrappeur-fou/
├── lib/
│   ├── dark_trader.rb
│   ├── mairie_scraper.rb
│   └── depute_scraper.rb
├── spec/
│   ├── spec_helper.rb
│   ├── dark_trader_spec.rb
│   ├── mairie_scraper_spec.rb
│   └── depute_scraper_spec.rb
├── Gemfile
├── .rspec
└── README.md
```

## Dependencies

- **nokogiri**: HTML/XML parsing
- **httparty**: HTTP requests
- **rspec**: Testing framework

## Author

Project made for The Hacking Project (THP).
